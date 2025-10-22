import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  UnauthorizedException,
  Patch,
  ParseIntPipe,
  BadRequestException,
  Query,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import * as path from 'path';
import * as fs from 'fs';
import type { Express } from 'express'; // Kiểu file upload (cần @types/multer)

import { UsersService } from './users.service';
import { ListDoctorsQueryDto } from './dto/list-doctors.query.dto';
import { RequestPasswordResetDto } from './dto/request-password-reset.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // POST /users/:id/avatar
  // Upload avatar cho user. Lưu file vào /uploads/avatars và cập nhật đường dẫn vào user.avatar
  @Post(':id/avatar')
  @UseInterceptors(
    FileInterceptor('avatar', {
      storage: diskStorage({
        destination: (req, file, cb) => {
          const uploadPath = path.join(__dirname, '../../uploads/avatars');
          fs.mkdirSync(uploadPath, { recursive: true });
          cb(null, uploadPath);
        },
        filename: (req, file, cb) => {
          const ext = path.extname(file.originalname);
          const name = `user_${req.params.id}_${Date.now()}${ext}`;
          cb(null, name);
        },
      }),
    }),
  )
  async uploadAvatar(
    @Param('id', ParseIntPipe) id: number,
    @UploadedFile() file: Express.Multer.File, // Nếu chưa cài @types/multer, tạm dùng: any
  ) {
    try {
      if (!file) throw new BadRequestException('No file uploaded');
      const avatarPath = `/uploads/avatars/${file.filename}`;
      const user = await this.usersService.updateUserProfile(id, { avatar: avatarPath });
      return { avatar: user.avatar };
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('Upload avatar error:', err);
      throw new BadRequestException('Upload avatar failed: ' + (err?.message || err));
    }
  }

  // GET /users?role=doctor&q=&city=&specialty=&minFee=&maxFee=&sort=&order=&page=&size=
  // Nếu role=doctor -> trả về dạng phân trang { data, meta }; ngược lại: findAll/findByRole
  @Get()
  findAll(@Query() query: ListDoctorsQueryDto) {
    if ((query.role ?? '').toLowerCase() === 'doctor') {
      return this.usersService.findDoctorsPaginated(query);
    }
    if (query.role) {
      return this.usersService.findByRole(query.role);
    }
    return this.usersService.findAll();
  }

  // GET /users/:id — lấy chi tiết 1 user
  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.usersService.findOne(id);
  }

  // POST /users — tạo user (giữ plain text để không phá dữ liệu hiện có)
  @Post()
  async create(@Body() data: any) {
    if (!data?.email || !data?.password) {
      throw new BadRequestException('Email và mật khẩu là bắt buộc');
    }
    return this.usersService.create(data);
  }

  // POST /users/login — đăng nhập (plain text – giữ để tương thích dữ liệu hiện tại)
  @Post('login')
  async login(@Body() body: { email: string; password: string }) {
    const user = await this.usersService.findByEmail(body.email);
    if (!user) throw new UnauthorizedException('Email không tồn tại!');
    if (user.password !== body.password) throw new UnauthorizedException('Mật khẩu không đúng!');
    // Ẩn password khi trả về
    const { password, ...result } = user as any;
    return result;
  }

  // PATCH /users/:id/profile — cập nhật profile (bệnh nhân & bác sĩ)
  @Patch(':id/profile')
  async updateProfile(@Param('id', ParseIntPipe) id: number, @Body() data: any) {
    return this.usersService.updateUserProfile(id, data);
  }

  // PATCH /users/change-password — đổi mật khẩu với oldPassword (giữ plain text)
  @Patch('change-password')
  async changePassword(
    @Body('email') email: string,
    @Body('oldPassword') oldPassword: string,
    @Body('newPassword') newPassword: string,
  ) {
    if (!email || !oldPassword || !newPassword) {
      throw new BadRequestException('Thiếu email/oldPassword/newPassword');
    }
    return this.usersService.changePassword(email, oldPassword, newPassword);
  }

  // ====== FLOW QUÊN MẬT KHẨU (code 4–6 số) ======

  // POST /users/request-password-reset — B1: gửi mã về email
  @Post('request-password-reset')
  async requestPasswordReset(@Body() dto: RequestPasswordResetDto) {
    await this.usersService.requestPasswordReset(dto.email);
    return { message: 'Code sent' };
  }

  // POST /users/reset-password — B2: nhập mã + đặt mật khẩu mới
  @Post('reset-password')
  async resetPassword(@Body() dto: ResetPasswordDto) {
    await this.usersService.resetPassword(dto.email, dto.code, dto.newPassword);
    return { message: 'Password updated' };
  }
}
