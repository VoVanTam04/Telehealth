import { IsEmail, IsNotEmpty, Length } from 'class-validator';

export class ResetPasswordDto {
  @IsEmail({}, { message: 'Email không hợp lệ' })
  @IsNotEmpty({ message: 'Email là bắt buộc' })
  email!: string;

  // mã 4–6 số; nếu dùng 6 số fix, để Length(6,6)
  @IsNotEmpty({ message: 'Mã xác nhận là bắt buộc' })
  @Length(4, 6, { message: 'Mã xác nhận phải 4–6 ký tự' })
  code!: string;

  @IsNotEmpty({ message: 'Mật khẩu mới là bắt buộc' })
  @Length(6, 100, { message: 'Mật khẩu mới tối thiểu 6 ký tự' })
  newPassword!: string;
}
