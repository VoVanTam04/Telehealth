// Module Users: khai báo repository, controller, service và import MailModule để gửi email

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { User } from './entities/user.entity';
import { PasswordReset } from './entities/password_reset.entity';

import { UsersService } from './users.service';
import { UsersController } from './users.controller';

import { MailModule } from '../mail/mail.module';

@Module({
  imports: [
    // Đăng ký repository cho 2 entity: User và PasswordReset vào DI container
    TypeOrmModule.forFeature([User, PasswordReset]),

    // Import MailModule để UsersService có thể inject MailService
    MailModule,
  ],
  controllers: [UsersController], // REST endpoints cho Users
  providers: [UsersService],      // nghiệp vụ Users
  exports: [
    TypeOrmModule, // export để module khác có thể reuse repo nếu cần
    UsersService,  // export service khi muốn gọi từ module khác
  ],
})
export class UsersModule {}
