//lọc & phân trang bác sĩ
import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class ListDoctorsQueryDto {
  // vẫn giữ tương thích FE: role=doctor sẽ kích hoạt nhánh phân trang/tìm kiếm
  @IsOptional()
  @IsString()
  role?: string;

  // tìm kiếm & lọc
  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  specialty?: string;

  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsNumber()
  minFee?: number;

  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsNumber()
  maxFee?: number;

  // sắp xếp
  @IsOptional()
  @IsIn(['id', 'name', 'fee'])
  sort?: 'id' | 'name' | 'fee';

  @IsOptional()
  @IsIn(['ASC', 'DESC'])
  order?: 'ASC' | 'DESC';

  // phân trang
  @Transform(({ value }) => Number(value ?? 1))
  @IsInt()
  @Min(1)
  page = 1;

  @Transform(({ value }) => Number(value ?? 20))
  @IsInt()
  @Min(1)
  @Max(100)
  size = 20;
}
