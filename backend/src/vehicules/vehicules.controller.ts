import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  Param,
  Patch,
  Post,
} from '@nestjs/common';

import { CreateVehiculeDto } from './dto/create-vehicule.dto';
import { UpdateVehiculeDto } from './dto/update-vehicule.dto';
import { VehiculesService } from './vehicules.service';

@Controller('vehicules')
export class VehiculesController {
  constructor(private readonly vehiculesService: VehiculesService) {}

  @Get()
  findAll(@Headers('authorization') authorization?: string) {
    return this.vehiculesService.findAll(authorization);
  }

  @Post()
  create(
    @Headers('authorization') authorization: string | undefined,
    @Body() dto: CreateVehiculeDto,
  ) {
    return this.vehiculesService.create(authorization, dto);
  }

  @Get(':id')
  findOne(
    @Headers('authorization') authorization: string | undefined,
    @Param('id') id: string,
  ) {
    return this.vehiculesService.findOne(authorization, id);
  }

  @Patch(':id')
  update(
    @Headers('authorization') authorization: string | undefined,
    @Param('id') id: string,
    @Body() dto: UpdateVehiculeDto,
  ) {
    return this.vehiculesService.update(authorization, id, dto);
  }

  @Delete(':id')
  remove(
    @Headers('authorization') authorization: string | undefined,
    @Param('id') id: string,
  ) {
    return this.vehiculesService.remove(authorization, id);
  }
}
