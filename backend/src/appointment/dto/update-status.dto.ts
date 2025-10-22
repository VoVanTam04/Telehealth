import { IsIn, IsOptional, IsString } from 'class-validator';
export class UpdateStatusDto {
  @IsIn(['CONFIRMED','REJECTED','CANCELLED','COMPLETED','NO_SHOW'])
  status: 'CONFIRMED'|'REJECTED'|'CANCELLED'|'COMPLETED'|'NO_SHOW';

  @IsOptional() @IsString() reason?: string; // cancelReason/rejectReason
}