// Bảng lưu yêu cầu reset password (nhiều lần theo thời gian)
// Lưu hash của mã 4–6 số, thời hạn, số lần nhập sai và dấu thời điểm đã dùng.

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  Index,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity('password_resets')
export class PasswordReset {
  @PrimaryGeneratedColumn('uuid')
  id: string; // định danh bản ghi reset

  // Quan hệ N-1 tới Users
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Index()
  @Column({ name: 'user_id' })
  userId: number; // id user (kiểu number vì User.id là number)

  @Column({ name: 'code_hash', type: 'nvarchar', length: 255 })
  codeHash: string; // hash của mã 4–6 số

  @Index()
  @Column({ name: 'expires_at', type: 'datetime2' })
  expiresAt: Date; // thời hạn hiệu lực của code

  @Column({ name: 'used_at', type: 'datetime2', nullable: true })
  usedAt?: Date | null; // đánh dấu đã dùng

  @Column({ name: 'attempt_count', type: 'int', default: 0 })
  attemptCount: number; // đếm số lần nhập sai

  @Column({ name: 'request_ip', type: 'nvarchar', length: 64, nullable: true })
  requestIp?: string | null; // IP yêu cầu (nếu muốn log)

  @CreateDateColumn({ name: 'created_at', type: 'datetime2' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'datetime2' })
  updatedAt: Date;
}
