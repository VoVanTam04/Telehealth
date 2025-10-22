// src/mail/mail.module.ts
import { Module } from '@nestjs/common';
import { MailService } from './mail.service';  // ← cùng thư mục → './mail.service'

@Module({
  providers: [MailService],
  exports: [MailService],
})
export class MailModule {}
