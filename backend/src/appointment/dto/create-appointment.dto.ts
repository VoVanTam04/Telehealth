import { IsInt, IsDateString, IsOptional, IsString, Min, IsNotEmpty } from 'class-validator';

export class CreateAppointmentDto {
  @IsInt()
  patientId: number;

  @IsInt()
  doctorId: number;

  // Expect ISO date string from client (e.g. 2025-10-21T08:30:00)
  @IsNotEmpty()
  @IsDateString()
  appointmentTime: string | Date;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  amount?: number;

  @IsOptional()
  @IsString()
  triageId?: string;
}
