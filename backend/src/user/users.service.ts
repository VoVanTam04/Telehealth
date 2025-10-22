// Service nghiệp vụ cho Users: CRUD, đổi profile, tìm bác sĩ, đổi mật khẩu, flow reset qua email

import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import {
  Repository,
  MoreThan, // so sánh ngày hết hạn > now
  IsNull,   // kiểm tra null cho usedAt
} from 'typeorm';

import * as bcrypt from 'bcryptjs'; // hash/compare mã & mật khẩu (nếu bạn muốn giữ plain-text cho changePassword, vẫn có thể dùng hash cho reset)
import { User } from './entities/user.entity';
import { PasswordReset } from './entities/password_reset.entity'; // <-- khớp đúng tên file bạn đã tạo
import { MailService } from '../mail/mail.service';
import { ListDoctorsQueryDto } from './dto/list-doctors.query.dto';

@Injectable()
export class UsersService {
  constructor(
    // Inject repository cho bảng Users
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,

    // Inject repository cho bảng password_resets
    @InjectRepository(PasswordReset)
    private readonly prRepo: Repository<PasswordReset>,

    // Dịch vụ gửi mail (SMTP Nodemailer)
    private readonly mailService: MailService,
  ) {}

  // Lấy tất cả người dùng (demo/dev)
  findAll(): Promise<User[]> {
    return this.userRepo.find();
  }

  // Lấy 1 user theo id
  findOne(id: number): Promise<User | null> {
    return this.userRepo.findOne({ where: { id } });
  }

  // Lấy 1 user theo email
  findByEmail(email: string): Promise<User | null> {
    return this.userRepo.findOne({ where: { email } });
  }

  // Tạo user mới (giữ nguyên logic không hash password để không phá dữ liệu cũ)
  async create(userData: Partial<User>): Promise<User> {
    try {
      const user = this.userRepo.create(userData);
      return await this.userRepo.save(user);
    } catch (e: any) {
      // Bắt lỗi unique email để trả message dễ hiểu
      if (
        e?.code === '23505' ||
        `${e?.message}`.includes('UNIQUE') ||
        `${e?.message}`.includes('unique')
      ) {
        throw new BadRequestException('Email đã tồn tại');
      }
      throw e;
    }
  }

  // Cập nhật profile (bệnh nhân/bác sĩ dùng chung)
  async updateUserProfile(id: number, data: any): Promise<User> {
    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) throw new NotFoundException('Không tìm thấy người dùng');

    user.name = data.name ?? user.name;
    user.email = data.email ?? user.email;
    user.avatar = data.avatar ?? user.avatar;
    user.gender = data.gender ?? user.gender;
    user.birthday = data.birthday ? new Date(data.birthday) : user.birthday;
    user.phone = data.phone ?? user.phone;
    user.address = data.address ?? user.address;
    user.specialty = data.specialty ?? user.specialty;
    user.fee = data.fee ?? user.fee;
    user.bank = data.bank ?? user.bank;
    user.bankAccount = data.bankAccount ?? user.bankAccount;
    user.city = data.city ?? user.city;

    return await this.userRepo.save(user);
  }

  // Lọc user theo role (vd: tất cả bác sĩ)
  findByRole(role: string): Promise<User[]> {
    return this.userRepo.find({ where: { role } });
  }

  // Đổi mật khẩu tức thời (yêu cầu nhập oldPassword) – để tương thích dữ liệu cũ, vẫn để plain text
  // GỢI Ý: Khi đã chuyển hẳn sang hash, thay so sánh bằng bcrypt.compare và lưu bằng hash.
  async changePassword(email: string, oldPassword: string, newPassword: string) {
    const user = await this.userRepo.findOne({ where: { email } });
    if (!user) throw new NotFoundException('Người dùng không tồn tại');

    if (user.password !== oldPassword) {
      throw new BadRequestException('Mật khẩu cũ không đúng');
    }

    user.password = newPassword; // giữ plain text theo dữ liệu hiện có
    await this.userRepo.save(user);

    // Gửi email thông báo (không chặn flow khi mail lỗi)
    try {
      await this.mailService.sendPasswordReset(
        email,
        'Mật khẩu của bạn đã được thay đổi thành công.',
      );
    } catch {
      // bỏ qua lỗi mail để tránh ảnh hưởng trải nghiệm
    }

    return { message: 'Đổi mật khẩu thành công' };
  }

  // B1: Yêu cầu mã reset (gửi mail code 4–6 số). Không lộ sự tồn tại email.
  async requestPasswordReset(email: string, ip?: string) {
    const user = await this.userRepo.findOne({ where: { email } });
    if (!user) return; // tránh lộ email

    // Sinh mã 6 số (có thể đổi thành 4–6 tuỳ ý)
    const code = ('' + Math.floor(100000 + Math.random() * 900000)).slice(-6);
    const codeHash = await bcrypt.hash(code, 10);

    // Tạo bản ghi password_resets (hạn 10 phút)
    const pr = this.prRepo.create({
      userId: user.id,
      codeHash,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      requestIp: ip,
    });
    await this.prRepo.save(pr);

    // Gửi email code (tái dùng sendPasswordReset cho nội dung mã)
    try {
      await this.mailService.sendPasswordReset(
        email,
        `Mã xác nhận đổi mật khẩu của bạn là ${code}. Mã có hiệu lực trong 10 phút.`,
      );
    } catch {
      // tránh làm fail cả flow nếu SMTP chưa cấu hình
    }
  }

  // B2: Đổi mật khẩu bằng code (verify code hợp lệ & chưa hết hạn), sau đó invalidate
  async resetPassword(email: string, code: string, newPassword: string) {
    const user = await this.userRepo.findOne({ where: { email } });
    if (!user) throw new BadRequestException('Invalid code');

    // Lấy reset record mới nhất còn hạn & chưa dùng
    const pr = await this.prRepo.findOne({
      where: {
        userId: user.id,
        usedAt: IsNull(),
        expiresAt: MoreThan(new Date()),
      },
      order: { createdAt: 'DESC' },
    });
    if (!pr) throw new BadRequestException('Invalid or expired code');

    // So sánh code người dùng nhập với codeHash
    const ok = await bcrypt.compare(code, pr.codeHash);
    if (!ok) {
      // tăng attempt_count để theo dõi brute-force (dùng QB để tránh lỗi cú pháp)
      await this.prRepo
        .createQueryBuilder()
        .update(PasswordReset)
        .set({ attemptCount: () => 'attempt_count + 1' })
        .where('id = :id', { id: pr.id })
        .execute();

      throw new BadRequestException('Invalid code');
    }

    // TẠM THỜI: giữ plain text cho đồng bộ dữ liệu cũ
    // KHUYẾN NGHỊ: chuyển sang hash: user.password = await bcrypt.hash(newPassword, 10);
    user.password = newPassword;
    await this.userRepo.save(user);

    // Invalidate mã (đánh dấu đã dùng)
    await this.prRepo.update(pr.id, { usedAt: new Date() });
  }

  /**
   * Phân trang + tìm kiếm/bộ lọc danh sách bác sĩ.
   * Trả về { data: User[], meta: { page, size, total, totalPages, sort, order, filters } }
   */
  async findDoctorsPaginated(qp: ListDoctorsQueryDto) {
    const {
      q,
      city,
      specialty,
      minFee,
      maxFee,
      sort = 'id',
      order = 'DESC',
      page,
      size,
    } = qp;

    // QueryBuilder lọc theo role = doctor
    const qb = this.userRepo
      .createQueryBuilder('u')
      .where('u.role = :role', { role: 'doctor' });

    // Tìm kiếm full-text đơn giản trên name/specialty/city
    if (q && q.trim()) {
      qb.andWhere(
        '(LOWER(u.name) LIKE LOWER(:kw) OR LOWER(u.specialty) LIKE LOWER(:kw) OR LOWER(u.city) LIKE LOWER(:kw))',
        { kw: `%${q.trim()}%` },
      );
    }

    // Lọc city
    if (city && city.trim()) {
      qb.andWhere('LOWER(u.city) = LOWER(:city)', { city: city.trim() });
    }

    // Lọc chuyên khoa
    if (specialty && specialty.trim()) {
      qb.andWhere('LOWER(u.specialty) = LOWER(:spec)', { spec: specialty.trim() });
    }

    // Khoảng phí
    if (minFee != null) {
      qb.andWhere('u.fee >= :minFee', { minFee });
    }
    if (maxFee != null) {
      qb.andWhere('u.fee <= :maxFee', { maxFee });
    }

    // Map sort an toàn
    const sortMap: Record<string, string> = {
      id: 'u.id',
      name: 'u.name',
      fee: 'u.fee',
    };
    qb.orderBy(sortMap[sort] ?? 'u.id', (order as 'ASC' | 'DESC') ?? 'DESC');

    // Tính tổng & phân trang
    const total = await qb.getCount();
    const pageNum = Number(page) && Number(page) > 0 ? Number(page) : 1;
    const sizeNum =
      Number(size) && Number(size) > 0 ? Number(size) : total || 10;
    const skip = (pageNum - 1) * sizeNum;

    const data = await qb.skip(skip).take(sizeNum).getMany();

    return {
      data,
      meta: {
        page: pageNum,
        size: sizeNum,
        total,
        totalPages: Math.max(1, Math.ceil(total / sizeNum)),
        sort,
        order,
        filters: { q, city, specialty, minFee, maxFee },
      },
    };
  }
}
