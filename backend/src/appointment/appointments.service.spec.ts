import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Appointment } from './appointment.entity';

@Injectable()
export class AppointmentsService {
  constructor(
    @InjectRepository(Appointment)
    private appointmentsRepository: Repository<Appointment>,
  ) {}

  // Lấy tất cả lịch hẹn
  findAll(): Promise<Appointment[]> {
    return this.appointmentsRepository.find();
  }

  // Lấy 1 lịch hẹn theo id
  findOne(id: number): Promise<Appointment | null> {
    return this.appointmentsRepository.findOneBy({ id });
  }

  // Tạo mới lịch hẹn
  create(data: Partial<Appointment>): Promise<Appointment> {
    const appointment = this.appointmentsRepository.create(data);
    return this.appointmentsRepository.save(appointment);
  }
}
