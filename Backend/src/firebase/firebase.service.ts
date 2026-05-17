import { Inject, Injectable } from '@nestjs/common';
import { app } from 'firebase-admin';
import { RemoteConfig, RemoteConfigParameter } from 'firebase-admin/remote-config';

@Injectable()
export class FirebaseService {
 private readonly remoteConfig: RemoteConfig;

     constructor(@Inject('FIREBASE_APP') private firebaseApp: app.App) {
    this.remoteConfig = this.firebaseApp.remoteConfig();
}
  async getRemoteConfig(): Promise<{
    [key: string]: RemoteConfigParameter;
}> {
    return (await this.remoteConfig.getTemplate()).parameters;

}
}