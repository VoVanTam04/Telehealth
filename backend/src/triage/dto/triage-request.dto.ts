// dto/triage-request.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, Min, Max, IsIn, IsOptional, IsString, Length } from 'class-validator';

export class TriageRequestDto {
  @ApiProperty({ example: 37, minimum: 0, maximum: 120 })
  @IsInt() @Min(0) @Max(120)
  age: number;

  @ApiProperty({ enum: ['male','female','other'], example: 'male' })
  @IsIn(['male','female','other'])
  gender: 'male' | 'female' | 'other';

  @ApiPropertyOptional({ maxLength: 300, example: 'tăng huyết áp' })
  @IsOptional() @IsString() @Length(0, 300)
  history?: string;

  @ApiProperty({ maxLength: 300, example: 'đau ngực 2 ngày gần đây, khó thở khi gắng sức' })
  @IsString() @Length(1, 300)
  symptoms: string;
}
