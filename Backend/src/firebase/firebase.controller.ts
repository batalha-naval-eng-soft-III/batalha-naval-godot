import { Controller, Get } from '@nestjs/common';
import { FirebaseService } from './firebase.service';

@Controller('')
export class FirebaseController {
  constructor(private readonly firebaseService: FirebaseService) {
 
  }

    @Get('remote-config')
  async getRemoteConfig() {
    return await this.firebaseService.getRemoteConfig();
  }
}
