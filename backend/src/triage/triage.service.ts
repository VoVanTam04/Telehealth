// src/triage/triage.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TriageLog } from './triage-log.entity';
import { TriageRequestDto } from './dto/triage-request.dto';
import { RuleBasedAIClient } from '../ai/rulebased.ai.client';

const ageToBand = (age: number) => {
  if (age <= 17) return '0-17';
  if (age <= 35) return '18-35';
  if (age <= 55) return '36-55';
  return '56+';
};

const extractKeywords = (text?: string) => {
  if (!text) return null;
  const t = text.toLowerCase();
  const dict = ['tăng huyết áp','đái tháo đường','tim mạch','hen','ung thư',
                'đau ngực','khó thở','sốt cao','co giật','đau bụng','ho','đau đầu'];
  const found = dict.filter(k => t.includes(k));
  return found.length ? found.join('; ') : null;
};

@Injectable()
export class TriageService {
  private ai = new RuleBasedAIClient();

  constructor(
    @InjectRepository(TriageLog) private readonly repo: Repository<TriageLog>,
  ) {}

  async inferAndLog(input: TriageRequestDto, userId?: string) {
    const aiRes = await this.ai.infer(input);

    const log = this.repo.create({
      userId: userId ?? null, // có thể null nếu bạn không muốn gắn cứng user
      ageBand: ageToBand(input.age),
      gender: input.gender,
      historyKeywords: extractKeywords(input.history),
      symptomKeywords: extractKeywords(input.symptoms),
      riskScore: aiRes.risk_score,
      riskLabel: aiRes.risk_label,
      suggestion: aiRes.suggestion ?? null,
    });

    const saved = await this.repo.save(log);

    return {
      risk_score: aiRes.risk_score,
      risk_label: aiRes.risk_label,
      suggestion: aiRes.suggestion,
      triage_id: saved.id,
      created_at: saved.createdAt.toISOString(),
    };
  }

  async getById(id: string) {
    const log = await this.repo.findOne({ where: { id } });
    if (!log) throw new NotFoundException('Triage not found');
    return {
      triage_id: log.id,
      risk_score: log.riskScore,
      risk_label: log.riskLabel,
      suggestion: log.suggestion,
      created_at: log.createdAt.toISOString(),
    };
  }
}
