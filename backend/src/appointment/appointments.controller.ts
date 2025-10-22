// src/appointments/appointments.controller.ts
import { Controller, Get, Post, Patch, Body, Param, Query, ParseIntPipe } from '@nestjs/common';
import { format } from 'date-fns';
import { AppointmentsService } from './appointments.service';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { UpdateStatusDto } from './dto/update-status.dto';
import { TriageService } from '../triage/triage.service';
import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';

@Controller('appointments')
export class AppointmentsController {
  constructor(
    private readonly appointmentsService: AppointmentsService,
    private readonly triageService: TriageService,
  ) {}
  // API lấy slot trống của bác sĩ theo ngày
  // GET /appointments/slots?doctorId=1&date=2025-10-15
  @Get('slots')
  async getDoctorSlots(
    @Query('doctorId', ParseIntPipe) doctorId: number,
    @Query('date') date: string,
  ) {
    // date: yyyy-MM-dd
    return this.appointmentsService.getDoctorSlots(doctorId, date);
  }

  // BN tạo yêu cầu
  @Post()
  create(@Body() dto: CreateAppointmentDto) {
    // debug: log incoming payload to help trace missing appointmentTime
    // eslint-disable-next-line no-console
    console.log('appointments.controller.create payload:', dto);
    return this.appointmentsService.create(dto);
  }

  // BN/BS xem danh sách của mình
  // GET /appointments/mine?role=patient&userId=1&status=PENDING
  @Get('mine')
  findMine(
    @Query('role') role: 'patient'|'doctor',
    @Query('userId', ParseIntPipe) userId: number,
    @Query('status') status?: string,
  ) {
    // debug
    // eslint-disable-next-line no-console
    console.log('appointments.controller.findMine called', { role, userId, status });
    return this.appointmentsService.findMine(role, userId, status);
  }

  // BS phê duyệt / từ chối / BN hủy / BS đánh dấu hoàn thành...
  // PATCH /appointments/:id/status
  @Patch(':id/status')
  updateStatus(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateStatusDto) {
    return this.appointmentsService.updateStatus(id, dto);
  }

   @Get(':id/triage')
  async getTriage(@Param('id', ParseIntPipe) id: number) {
    const appt = await this.appointmentsService.findOne(id);
    if (!appt) throw new NotFoundException('Appointment not found');
    if (!appt.triageId) throw new NotFoundException('No triage for this appointment');
    // Tái dùng service triage để trả định dạng chuẩn
    return this.triageService.getById(appt.triageId);
  }
}
