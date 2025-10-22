import { Module } from '@nestjs/common';
import { AgoraController } from './agora.controller';

@Module({
  controllers: [AgoraController],
  providers: [],
  exports: [],
})
export class VideoModule {}
