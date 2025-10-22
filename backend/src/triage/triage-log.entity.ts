// src/triage/triage-log.entity.ts
import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, Index } from 'typeorm';

@Entity('triage_logs')
export class TriageLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // Không lưu PII như tên, email. Chỉ lưu userId nội bộ để truy xuất trong phiên
  @Index()
  @Column({ type: 'uniqueidentifier', nullable: true }) // nếu DB bạn không dùng uniqueidentifier, chuyển sang nvarchar(36)
  userId: string | null;

  @Column({ type: 'nvarchar', length: 16 })
  ageBand: string; // "0-17" | "18-35" | "36-55" | "56+"

  @Column({ type: 'nvarchar', length: 10 })
  gender: 'male' | 'female' | 'other';

  @Column({ type: 'nvarchar', length: 400, nullable: true })
  historyKeywords: string | null; // "tăng huyết áp; đái tháo đường"

  @Column({ type: 'nvarchar', length: 400, nullable: true })
  symptomKeywords: string | null; // "đau ngực; khó thở"

  @Column({ type: 'float' })
  riskScore: number; // 0..1

  @Column({ type: 'nvarchar', length: 16 })
  riskLabel: 'Thấp' | 'Trung bình' | 'Cao';

  @Column({ type: 'nvarchar', length: 200, nullable: true })
  suggestion: string | null;

  @CreateDateColumn({ type: 'datetime2' })
  createdAt: Date;
}
