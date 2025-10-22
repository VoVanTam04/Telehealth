// src/appointments/appointments.service.ts

import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { format } from 'date-fns';
import { Appointment } from './appointment.entity';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { UpdateStatusDto } from './dto/update-status.dto';
import { MailService } from '../mail/mail.service';
import { UsersService } from '../user/users.service';

@Injectable()
export class AppointmentsService {
  constructor(
    @InjectRepository(Appointment)
    private readonly repo: Repository<Appointment>,
    private readonly mailService: MailService,
    private readonly usersService: UsersService,
  ) {}

  /** BN tạo yêu cầu lịch (mặc định PENDING, UNPAID) */
  async create(dto: CreateAppointmentDto) {
    // Hỗ trợ cả string và Date; log khi sai để debug nhanh
    const rawInput = dto.appointmentTime as any;
    const at = new Date(rawInput);
    if (isNaN(at.getTime())) {
      // eslint-disable-next-line no-console
      console.error('Invalid appointmentTime payload:', rawInput);
      throw new BadRequestException('Invalid appointmentTime');
    }

    const now = new Date();
    if (at.getTime() < now.getTime() - 60_000) {
      throw new BadRequestException('appointmentTime must be in the future');
    }

    const appt = this.repo.create({
      patientId: dto.patientId,
      doctorId: dto.doctorId,
      appointmentTime: at,
      note: dto.note ?? null,
      // Keep `amount` nullable: if client didn't supply amount, store null
      // so frontend can treat null as "QR động" (enter amount when scanning).
      amount: dto.amount ?? null,
      status: 'PENDING',
      paymentStatus: 'UNPAID',
      paymentRef: null,
      cancelReason: null,
      rejectReason: null,
      triageId: dto.triageId ?? null, // lưu mã sàng lọc nếu có
    });

    const saved = await this.repo.save(appt);

    // Return enriched shape (include doctor info) so FE can immediately show bank/account/fee
    // similar to findMine mapping (raw aliased fields)
    const qb = this.repo.createQueryBuilder('a')
      .leftJoin('users', 'u', 'a.doctorId = u.id')
      .select([
        'a.id as id',
        'a.appointmentTime as appointmentTime',
        'a.patientId as patientId',
        'a.doctorId as doctorId',
        'a.note as note',
        'a.amount as amount',
        'a.paymentStatus as paymentStatus',
        'a.paymentRef as paymentRef',
        'u.name as doctorName',
        'u.specialty as doctorSpecialty',
        'u.bank as doctorBank',
        'u.bankAccount as doctorBankAccount',
        'u.city as doctorCity',
        'u.fee as doctorFee',
      ])
      .where('a.id = :id', { id: saved.id });

  const rawAppt = await qb.getRawOne();
  return rawAppt;
  }

  /** Lấy 1 lịch theo id (cho /appointments/:id/triage) */
  findOne(id: number): Promise<Appointment | null> {
    return this.repo.findOne({ where: { id } });
  }

  /** Lấy slot trống của bác sĩ theo ngày */
  async getDoctorSlots(doctorId: number, date: string) {
    // Chuẩn hoá ngày: chấp nhận 'yyyy-MM-dd' hoặc ISO → luôn về yyyy-MM-dd
    let dayOnly: string;
    const parsed = new Date(date);
    if (!isNaN(parsed.getTime())) {
      const yyyy = String(parsed.getFullYear()).padStart(4, '0');
      const mm = String(parsed.getMonth() + 1).padStart(2, '0');
      const dd = String(parsed.getDate()).padStart(2, '0');
      dayOnly = `${yyyy}-${mm}-${dd}`;
    } else {
      // nếu là chuỗi yyyy-MM-dd
      dayOnly = date.slice(0, 10);
    }

    // Sinh slot 30'
    const slots: string[] = [];
    for (let h = 8; h < 17; h++) {
      const hh = String(h).padStart(2, '0');
      slots.push(`${dayOnly}T${hh}:00:00`);
      slots.push(`${dayOnly}T${hh}:30:00`);
    }

    // Lấy các lịch đã đặt trong ngày
    const start = new Date(`${dayOnly}T00:00:00`);
    const end = new Date(`${dayOnly}T23:59:59`);

    const appts = await this.repo.find({
      where: {
        doctorId,
        appointmentTime: Between(start, end),
      },
    });

    const booked = appts
      .filter((a) => a.appointmentTime)
      .map((a) => format(a.appointmentTime as Date, "yyyy-MM-dd'T'HH:mm:ss"));

    return slots.filter((s) => !booked.includes(s));
  }

  /** Lấy danh sách của chính BN/BS; có thể lọc theo status */
  async findMine(role: 'patient' | 'doctor', userId: number, status?: string) {
    // debug log
    // eslint-disable-next-line no-console
    console.log('AppointmentsService.findMine called with', { role, userId, status });

    if (!['patient', 'doctor'].includes(role)) {
      throw new BadRequestException('role must be "patient" or "doctor"');
    }
    if (!Number.isFinite(userId)) {
      throw new BadRequestException('userId invalid');
    }

    const where: any =
      role === 'patient' ? { patientId: userId } : { doctorId: userId };
    if (status) where.status = status;

    try {
      const qb = this.repo.createQueryBuilder('a')
        .leftJoin('users', 'u', 'a.doctorId = u.id')
        .addSelect([
          'u.name',
          'u.specialty',
          'u.bank',
          'u.bankAccount',
          'u.city',
          'u.fee',
        ])
        .orderBy('a.appointmentTime', 'DESC');

      // Áp dụng điều kiện theo role/userId/status một cách an toàn
      if (role === 'patient') {
        qb.andWhere('a.patientId = :userId', { userId });
      } else {
        qb.andWhere('a.doctorId = :userId', { userId });
      }

      if (status) {
        qb.andWhere('a.status = :status', { status });
      }

      const appts = await qb.getRawMany();

      return appts.map((a) => ({
        id: a.a_id,
        ...a,
        appointmentTime: a.a_appointmentTime
          ? format(new Date(a.a_appointmentTime), "yyyy-MM-dd'T'HH:mm:ss")
          : null,
        doctorName: a.u_name ?? '',
        doctorSpecialty: a.u_specialty ?? '',
        doctorBank: a.u_bank ?? '',
        doctorBankAccount: a.u_bankAccount ?? '',
        doctorCity: a.u_city ?? '',
        doctorFee: a.u_fee ?? 0,
      }));
    } catch (err) {
      // Log error để dễ debug (Nest sẽ trả 500 nếu ném tiếp)
      // eslint-disable-next-line no-console
      console.error('Error in AppointmentsService.findMine:', err);
      throw err;
    }
  }

  /** Cập nhật trạng thái */
  async updateStatus(id: number, dto: UpdateStatusDto) {
    if (!Number.isFinite(id)) throw new BadRequestException('Invalid id');

    const appt = await this.repo.findOne({ where: { id } });
    if (!appt) throw new NotFoundException('Appointment not found');

  switch (dto.status) {
      case 'CONFIRMED': {
        if (appt.status !== 'PENDING') {
          throw new BadRequestException('Only PENDING can be confirmed');
        }
        appt.status = 'CONFIRMED';
        appt.rejectReason = null;

        // Đánh dấu slot của bác sĩ là bận
        const doctorId = appt.doctorId;
        const appointmentTime = appt.appointmentTime;
        if (doctorId && appointmentTime) {
          const busySlot = await this.repo.findOne({
            where: { doctorId, appointmentTime, status: 'BUSY' as any },
          });
          if (!busySlot) {
            await this.repo.save({
              doctorId,
              appointmentTime,
              status: 'BUSY' as any,
            } as any);
          }
        }

        // Gửi email thông báo cho bệnh nhân khi lịch được xác nhận
        try {
          const patient = appt.patientId ? await this.usersService.findOne(appt.patientId) : null;
          const patientEmail = patient?.email;
          if (patientEmail) {
            await this.mailService.sendPasswordReset(
              patientEmail,
              `Lịch khám của bạn với bác sĩ đã được xác nhận. Thời gian: ${appointmentTime}`
            );
          }
        } catch (e) {
          // Không chặn flow nếu gửi mail lỗi
        }
        break;
      }
      case 'REJECTED': {
        if (appt.status !== 'PENDING') {
          throw new BadRequestException('Only PENDING can be rejected');
        }
        appt.status = 'REJECTED';
        appt.rejectReason = dto.reason ?? null;
        break;
      }
      case 'CANCELLED': {
        if (!['PENDING', 'CONFIRMED'].includes(appt.status)) {
          throw new BadRequestException('Cannot cancel at current status');
        }
        appt.status = 'CANCELLED';
        appt.cancelReason = dto.reason ?? null;
        break;
      }
      case 'COMPLETED': {
        if (appt.status !== 'CONFIRMED') {
          throw new BadRequestException('Only CONFIRMED can be completed');
        }
        appt.status = 'COMPLETED';
        break;
      }
      case 'NO_SHOW': {
        if (appt.status !== 'CONFIRMED') {
          throw new BadRequestException('Only CONFIRMED can be marked no-show');
        }
        appt.status = 'NO_SHOW';
        break;
      }
      default:
        throw new BadRequestException('Unsupported status');
    }

    await this.repo.save(appt);
    return appt;
  }
}
