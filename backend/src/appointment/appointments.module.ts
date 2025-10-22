import { Module } from '@nestjs/common';
import { AppointmentsService } from './appointments.service';
import { AppointmentsController } from './appointments.controller';
import { Appointment } from './appointment.entity';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TriageModule } from '../triage/triage.module';
import { MailModule } from '../mail/mail.module';
import { UsersModule } from '../user/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Appointment]),
    TriageModule,
    MailModule,
    UsersModule,
  ],
  providers: [AppointmentsService],
  controllers: [AppointmentsController],
  exports: [TypeOrmModule],
})
export class AppointmentsModule {}
