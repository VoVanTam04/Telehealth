// Bảng Users chứa cả bệnh nhân & bác sĩ, kèm các trường hồ sơ và vài trường reset legacy

import { Entity, Column, PrimaryGeneratedColumn, Index } from 'typeorm';

@Index('idx_user_role', ['role'])
@Index('idx_user_city', ['city'])
@Index('idx_user_specialty', ['specialty'])
@Entity({ name: 'Users' }) // tên bảng trong SQL Server là "Users"
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'nvarchar', length: 100, nullable: true })
  name: string | null;

  @Column({ type: 'nvarchar', length: 100, unique: true, nullable: true })
  email: string | null;

  @Column({ type: 'nvarchar', length: 100, nullable: true })
  password: string | null; // hiện tại đang lưu plain-text để tương thích; khuyến nghị chuyển sang hash

  @Column({ type: 'nvarchar', length: 20, nullable: true })
  role: string | null; // 'patient' | 'doctor'

  @Column({ type: 'nvarchar', length: 255, nullable: true })
  avatar: string | null;

  // Thông tin bổ sung cho bệnh nhân
  @Column({ type: 'nvarchar', length: 10, nullable: true })
  gender: string | null;

  @Column({ type: 'date', nullable: true })
  birthday: Date | null;

  @Column({ type: 'nvarchar', length: 20, nullable: true })
  phone: string | null;

  @Column({ type: 'nvarchar', length: 255, nullable: true })
  address: string | null;

  // Các trường reset legacy (nếu đã có sẵn); khi dùng bảng password_resets có thể bỏ qua
  @Column({ type: 'nvarchar', length: 128, nullable: true })
  resetTokenHash: string | null;

  @Column({ type: 'datetime2', nullable: true })
  resetTokenExpiresAt: Date | null;

  // Hồ sơ bác sĩ
  @Column({ type: 'nvarchar', length: 100, nullable: true })
  specialty: string | null;

  @Column({ type: 'int', nullable: true })
  fee: number | null;

  @Column({ type: 'nvarchar', length: 50, nullable: true })
  bank: string | null; // ví dụ: 'bidv'

  @Column({ type: 'nvarchar', length: 50, nullable: true })
  bankAccount: string | null; // STK

  @Column({ type: 'nvarchar', length: 100, nullable: true })
  city: string | null;
}
