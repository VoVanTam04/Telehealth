import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './user/users.module';
import { AppointmentsModule } from './appointment/appointments.module';
import { ConfigModule } from '@nestjs/config';
import { VideoModule } from './video/video.module';
import type { SqlServerConnectionOptions } from 'typeorm/driver/sqlserver/SqlServerConnectionOptions';
import { TriageModule } from './triage/triage.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),

    // ✅ Chỉ set instanceName khi .env có DB_INSTANCE
    TypeOrmModule.forRoot((() => {
      const isNamed = !!process.env.DB_INSTANCE && process.env.DB_INSTANCE.trim() !== '';
      const options: SqlServerConnectionOptions['options'] = {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
        ...(isNamed ? { instanceName: process.env.DB_INSTANCE } : {}),
      };
      return {
        type: 'mssql',
        host: process.env.DB_HOST || '127.0.0.1',
        // Với named instance: bỏ port (driver tự hỏi SQL Browser)
        ...(isNamed ? {} : { port: Number(process.env.DB_PORT || 1433) }),
        username: process.env.DB_USER || 'sa',
        password: process.env.DB_PASS || '123456',
        database: process.env.DB_NAME || 'telehealth_db',
        autoLoadEntities: true,
        synchronize: false,
        logging: ['error', 'warn'],
        options,
      } as SqlServerConnectionOptions;
    })()),
    TriageModule,
    UsersModule,
    AppointmentsModule,
    VideoModule,
  ],
})
export class AppModule {}
