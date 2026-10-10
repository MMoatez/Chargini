import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { User, UserSchema } from '../users/schemas/user.schema';
import { UsersModule } from '../users/users.module';
import { Vehicule, VehiculeSchema } from './schemas/vehicule.schema';
import { VehiculesController } from './vehicules.controller';
import { VehiculesService } from './vehicules.service';

@Module({
  imports: [
    UsersModule,
    MongooseModule.forFeature([
      { name: Vehicule.name, schema: VehiculeSchema },
      { name: User.name, schema: UserSchema },
    ]),
  ],
  controllers: [VehiculesController],
  providers: [VehiculesService],
})
export class VehiculesModule {}
