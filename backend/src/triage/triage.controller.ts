import { Controller, Post, Body, Req, HttpCode, Get, Param } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiBody, ApiOkResponse, ApiBadRequestResponse, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { TriageService } from './triage.service';
import { TriageRequestDto } from './dto/triage-request.dto';
import { TriageResponseDto } from './dto/triage-response.dto';

@ApiTags('Triage')
@ApiBearerAuth()
@Controller('api/triage')
export class TriageController {
  constructor(private readonly triageService: TriageService) {}

  @Post('infer')
  @ApiBody({ type: TriageRequestDto, description: 'Thông tin sàng lọc trước khám' })
  @ApiOkResponse({ type: TriageResponseDto, description: 'Kết quả đánh giá nguy cơ' })
  @ApiBadRequestResponse({ description: 'Body không hợp lệ' })
  @ApiUnauthorizedResponse({ description: 'Thiếu hoặc sai Bearer token' })
  @HttpCode(200)
  async infer(@Body() dto: TriageRequestDto, @Req() req: any) {
    const userId = req?.user?.id ?? null;
    return this.triageService.inferAndLog(dto, userId);
  }

  @Get(':id')
  async getOne(@Param('id') id: string) {
    return this.triageService.getById(id);
  }
}
