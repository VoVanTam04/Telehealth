import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity({ name: 'Appointments' })
export class Appointment {
  @PrimaryGeneratedColumn() id: number;

  @Column({ type: 'int', nullable: true }) patientId: number | null;
  @Column({ type: 'int', nullable: true }) doctorId: number | null;

  @Column({ type: 'datetime2', nullable: true }) appointmentTime: Date | null;

  @Column({ type: 'nvarchar', length: 'MAX', nullable: true })
  note: string | null; // ⬅️ cho phép null

  @Column({ type: 'int', nullable: true })
  amount: number | null; // ⬅️

  @Column({ type: 'nvarchar', length: 20, default: 'UNPAID' })
  paymentStatus: string;

  @Column({ type: 'nvarchar', length: 100, nullable: true })
  paymentRef: string | null; // ⬅️

  @Column({ type: 'nvarchar', length: 20, default: 'PENDING' })
  status: string;

  @Column({ type: 'datetime2', default: () => 'SYSUTCDATETIME()' })
  createdAt: Date;

  @Column({ type: 'datetime2', default: () => 'SYSUTCDATETIME()' })
  updatedAt: Date;

  @Column({ type: 'nvarchar', length: 255, nullable: true })
  cancelReason: string | null; // ⬅️

  @Column({ type: 'nvarchar', length: 255, nullable: true })
  rejectReason: string | null; // ⬅️

  @Column({ type: 'nvarchar', length: 36, nullable: true })
  triageId: string | null;
}
