import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TriageLog } from './triage-log.entity';
import { TriageService } from './triage.service';
import { TriageController } from './triage.controller';

@Module({
  imports: [TypeOrmModule.forFeature([TriageLog])],
  controllers: [TriageController],
  providers: [TriageService],
  exports: [TriageService],
})
export class TriageModule {}