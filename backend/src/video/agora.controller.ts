import { Controller, Get, Query, BadRequestException } from '@nestjs/common';
import { RtcTokenBuilder, RtcRole } from 'agora-access-token';

@Controller('video')
export class AgoraController {
  @Get('agora-token')
  getAgoraToken(
    @Query('channel') channel: string,
    @Query('uid') uidRaw: string,
  ) {
    if (!channel) throw new BadRequestException('channel is required');
    const uid = Number(uidRaw ?? 0);
    if (Number.isNaN(uid)) throw new BadRequestException('uid must be a number');

    // TODO: chuyển các giá trị này sang biến môi trường .env
    const appID = 'f251c48a11e3498dacd358e1fb6e6958';
    const appCertificate = 'f048c31799de4b9d8f899f820d3863c6';
    const role = RtcRole.PUBLISHER;
    const expireTime = 3600; // 1 giờ

    const token = RtcTokenBuilder.buildTokenWithUid(
      appID,
      appCertificate,
      channel,
      uid,
      role,
      expireTime,
    );

    return { token };
  }
}
