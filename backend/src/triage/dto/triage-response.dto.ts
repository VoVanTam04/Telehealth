// dto/triage-response.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class TriageResponseDto {
  @ApiProperty({ example: 0.78 })
  risk_score: number;

  @ApiProperty({ enum: ['Thấp','Trung bình','Cao'], example: 'Cao' })
  risk_label: 'Thấp' | 'Trung bình' | 'Cao';

  @ApiPropertyOptional({ example: 'Ưu tiên đặt trong 24h với BS Tim mạch' })
  suggestion?: string;

  @ApiProperty({ example: 'a1b2c3d4-...-zz' })
  triage_id: string;

  @ApiProperty({ example: '2025-10-20T07:21:00.000Z' })
  created_at: string;
}
