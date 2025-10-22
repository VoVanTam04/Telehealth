//cập nhật profile bác sĩ
import { IsOptional, IsInt, Min, IsString, MaxLength } from 'class-validator';

export class UpdateDoctorProfileDto {
  @IsOptional() @IsString() @MaxLength(100) specialty?: string;
  @IsOptional() @IsInt() @Min(0) fee?: number;
  @IsOptional() @IsString() @MaxLength(50) bank?: string;         // 'bidv','techcombank',...
  @IsOptional() @IsString() @MaxLength(50) bankAccount?: string;   // STK
  @IsOptional() @IsString() @MaxLength(100) city?: string;
}