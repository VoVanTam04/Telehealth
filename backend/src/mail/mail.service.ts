import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private transporter: nodemailer.Transporter;

  constructor(private readonly config: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.config.get<string>('MAIL_HOST'),
      port: Number(this.config.get<number>('MAIL_PORT') ?? 465),
      secure: (this.config.get<string>('MAIL_SECURE') ?? 'true') === 'true',
      auth: {
        user: this.config.get<string>('MAIL_USER'),
        pass: this.config.get<string>('MAIL_PASS'),
      },
      logger: true, // log chi tiết
      debug: true,  // log chi tiết
    });

    // => In ra lỗi cấu hình/login nếu có
    this.transporter.verify((err) => {
      if (err) this.logger.error('SMTP verify failed: ' + (err?.message || err));
      else this.logger.log('SMTP server is ready to take messages');
    });
  }

  async sendPasswordReset(to: string, noteOrUrl: string) {
    const from = this.config.get<string>('MAIL_FROM') || 'Telehealth <no-reply@telehealth.local>';
    const subject = 'Telehealth - Đổi mật khẩu';
    const html = `<div><p>Chào bạn,</p><p>${noteOrUrl}</p><p>Nếu không phải bạn thực hiện, hãy liên hệ hỗ trợ.</p></div>`;

    const info = await this.transporter.sendMail({ from, to, subject, html });

    // log messageId để đối chiếu
    this.logger.log(`Mail sent to ${to} (messageId: ${info.messageId})`);
  }
}
