import agg_basics, strutils, agg_trans_affine, agg_conv_transform
import agg_conv_stroke, agg_math_stroke, agg_bounding_rect

export agg_conv_stroke

var gsv_default_font = [
  0x40'u8,0x00,0x6c,0x0f,0x15,0x00,0x0e,0x00,0xf9,0xff,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x0d,0x0a,0x0d,0x0a,0x46,0x6f,0x6e,0x74,0x20,0x28,
  0x63,0x29,0x20,0x4d,0x69,0x63,0x72,0x6f,0x50,0x72,
  0x6f,0x66,0x20,0x32,0x37,0x20,0x53,0x65,0x70,0x74,
  0x65,0x6d,0x62,0x2e,0x31,0x39,0x38,0x39,0x00,0x0d,
  0x0a,0x0d,0x0a,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x02,0x00,0x12,0x00,0x34,0x00,0x46,0x00,0x94,0x00,
  0xd0,0x00,0x2e,0x01,0x3e,0x01,0x64,0x01,0x8a,0x01,
  0x98,0x01,0xa2,0x01,0xb4,0x01,0xba,0x01,0xc6,0x01,
  0xcc,0x01,0xf0,0x01,0xfa,0x01,0x18,0x02,0x38,0x02,
  0x44,0x02,0x68,0x02,0x98,0x02,0xa2,0x02,0xde,0x02,
  0x0e,0x03,0x24,0x03,0x40,0x03,0x48,0x03,0x52,0x03,
  0x5a,0x03,0x82,0x03,0xec,0x03,0xfa,0x03,0x26,0x04,
  0x4c,0x04,0x6a,0x04,0x7c,0x04,0x8a,0x04,0xb6,0x04,
  0xc4,0x04,0xca,0x04,0xe0,0x04,0xee,0x04,0xf8,0x04,
  0x0a,0x05,0x18,0x05,0x44,0x05,0x5e,0x05,0x8e,0x05,
  0xac,0x05,0xd6,0x05,0xe0,0x05,0xf6,0x05,0x00,0x06,
  0x12,0x06,0x1c,0x06,0x28,0x06,0x36,0x06,0x48,0x06,
  0x4e,0x06,0x60,0x06,0x6e,0x06,0x74,0x06,0x84,0x06,
  0xa6,0x06,0xc8,0x06,0xe6,0x06,0x08,0x07,0x2c,0x07,
  0x3c,0x07,0x68,0x07,0x7c,0x07,0x8c,0x07,0xa2,0x07,
  0xb0,0x07,0xb6,0x07,0xd8,0x07,0xec,0x07,0x10,0x08,
  0x32,0x08,0x54,0x08,0x64,0x08,0x88,0x08,0x98,0x08,
  0xac,0x08,0xb6,0x08,0xc8,0x08,0xd2,0x08,0xe4,0x08,
  0xf2,0x08,0x3e,0x09,0x48,0x09,0x94,0x09,0xc2,0x09,
  0xc4,0x09,0xd0,0x09,0xe2,0x09,0x04,0x0a,0x0e,0x0a,
  0x26,0x0a,0x34,0x0a,0x4a,0x0a,0x66,0x0a,0x70,0x0a,
  0x7e,0x0a,0x8e,0x0a,0x9a,0x0a,0xa6,0x0a,0xb4,0x0a,
  0xd8,0x0a,0xe2,0x0a,0xf6,0x0a,0x18,0x0b,0x22,0x0b,
  0x32,0x0b,0x56,0x0b,0x60,0x0b,0x6e,0x0b,0x7c,0x0b,
  0x8a,0x0b,0x9c,0x0b,0x9e,0x0b,0xb2,0x0b,0xc2,0x0b,
  0xd8,0x0b,0xf4,0x0b,0x08,0x0c,0x30,0x0c,0x56,0x0c,
  0x72,0x0c,0x90,0x0c,0xb2,0x0c,0xce,0x0c,0xe2,0x0c,
  0xfe,0x0c,0x10,0x0d,0x26,0x0d,0x36,0x0d,0x42,0x0d,
  0x4e,0x0d,0x5c,0x0d,0x78,0x0d,0x8c,0x0d,0x8e,0x0d,
  0x90,0x0d,0x92,0x0d,0x94,0x0d,0x96,0x0d,0x98,0x0d,
  0x9a,0x0d,0x9c,0x0d,0x9e,0x0d,0xa0,0x0d,0xa2,0x0d,
  0xa4,0x0d,0xa6,0x0d,0xa8,0x0d,0xaa,0x0d,0xac,0x0d,
  0xae,0x0d,0xb0,0x0d,0xb2,0x0d,0xb4,0x0d,0xb6,0x0d,
  0xb8,0x0d,0xba,0x0d,0xbc,0x0d,0xbe,0x0d,0xc0,0x0d,
  0xc2,0x0d,0xc4,0x0d,0xc6,0x0d,0xc8,0x0d,0xca,0x0d,
  0xcc,0x0d,0xce,0x0d,0xd0,0x0d,0xd2,0x0d,0xd4,0x0d,
  0xd6,0x0d,0xd8,0x0d,0xda,0x0d,0xdc,0x0d,0xde,0x0d,
  0xe0,0x0d,0xe2,0x0d,0xe4,0x0d,0xe6,0x0d,0xe8,0x0d,
  0xea,0x0d,0xec,0x0d,0x0c,0x0e,0x26,0x0e,0x48,0x0e,
  0x64,0x0e,0x88,0x0e,0x92,0x0e,0xa6,0x0e,0xb4,0x0e,
  0xd0,0x0e,0xee,0x0e,0x02,0x0f,0x16,0x0f,0x26,0x0f,
  0x3c,0x0f,0x58,0x0f,0x6c,0x0f,0x6c,0x0f,0x6c,0x0f,
  0x6c,0x0f,0x6c,0x0f,0x6c,0x0f,0x6c,0x0f,0x6c,0x0f,
  0x6c,0x0f,0x6c,0x0f,0x6c,0x0f,0x6c,0x0f,0x6c,0x0f,
  0x6c,0x0f,0x6c,0x0f,0x6c,0x0f,0x6c,0x0f,0x10,0x80,
  0x05,0x95,0x00,0x72,0x00,0xfb,0xff,0x7f,0x01,0x7f,
  0x01,0x01,0xff,0x01,0x05,0xfe,0x05,0x95,0xff,0x7f,
  0x00,0x7a,0x01,0x86,0xff,0x7a,0x01,0x87,0x01,0x7f,
  0xfe,0x7a,0x0a,0x87,0xff,0x7f,0x00,0x7a,0x01,0x86,
  0xff,0x7a,0x01,0x87,0x01,0x7f,0xfe,0x7a,0x05,0xf2,
  0x0b,0x95,0xf9,0x64,0x0d,0x9c,0xf9,0x64,0xfa,0x91,
  0x0e,0x00,0xf1,0xfa,0x0e,0x00,0x04,0xfc,0x08,0x99,
  0x00,0x63,0x04,0x9d,0x00,0x63,0x04,0x96,0xff,0x7f,
  0x01,0x7f,0x01,0x01,0x00,0x01,0xfe,0x02,0xfd,0x01,
  0xfc,0x00,0xfd,0x7f,0xfe,0x7e,0x00,0x7e,0x01,0x7e,
  0x01,0x7f,0x02,0x7f,0x06,0x7e,0x02,0x7f,0x02,0x7e,
  0xf2,0x89,0x02,0x7e,0x02,0x7f,0x06,0x7e,0x02,0x7f,
  0x01,0x7f,0x01,0x7e,0x00,0x7c,0xfe,0x7e,0xfd,0x7f,
  0xfc,0x00,0xfd,0x01,0xfe,0x02,0x00,0x01,0x01,0x01,
  0x01,0x7f,0xff,0x7f,0x10,0xfd,0x15,0x95,0xee,0x6b,
  0x05,0x95,0x02,0x7e,0x00,0x7e,0xff,0x7e,0xfe,0x7f,
  0xfe,0x00,0xfe,0x02,0x00,0x02,0x01,0x02,0x02,0x01,
  0x02,0x00,0x02,0x7f,0x03,0x7f,0x03,0x00,0x03,0x01,
  0x02,0x01,0xfc,0xf2,0xfe,0x7f,0xff,0x7e,0x00,0x7e,
  0x02,0x7e,0x02,0x00,0x02,0x01,0x01,0x02,0x00,0x02,
  0xfe,0x02,0xfe,0x00,0x07,0xf9,0x15,0x8d,0xff,0x7f,
  0x01,0x7f,0x01,0x01,0x00,0x01,0xff,0x01,0xff,0x00,
  0xff,0x7f,0xff,0x7e,0xfe,0x7b,0xfe,0x7d,0xfe,0x7e,
  0xfe,0x7f,0xfd,0x00,0xfd,0x01,0xff,0x02,0x00,0x03,
  0x01,0x02,0x06,0x04,0x02,0x02,0x01,0x02,0x00,0x02,
  0xff,0x02,0xfe,0x01,0xfe,0x7f,0xff,0x7e,0x00,0x7e,
  0x01,0x7d,0x02,0x7d,0x05,0x79,0x02,0x7e,0x03,0x7f,
  0x01,0x00,0x01,0x01,0x00,0x01,0xf1,0xfe,0xfe,0x01,
  0xff,0x02,0x00,0x03,0x01,0x02,0x02,0x02,0x00,0x86,
  0x01,0x7e,0x08,0x75,0x02,0x7e,0x02,0x7f,0x05,0x80,
  0x05,0x93,0xff,0x01,0x01,0x01,0x01,0x7f,0x00,0x7e,
  0xff,0x7e,0xff,0x7f,0x06,0xf1,0x0b,0x99,0xfe,0x7e,
  0xfe,0x7d,0xfe,0x7c,0xff,0x7b,0x00,0x7c,0x01,0x7b,
  0x02,0x7c,0x02,0x7d,0x02,0x7e,0xfe,0x9e,0xfe,0x7c,
  0xff,0x7d,0xff,0x7b,0x00,0x7c,0x01,0x7b,0x01,0x7d,
  0x02,0x7c,0x05,0x85,0x03,0x99,0x02,0x7e,0x02,0x7d,
  0x02,0x7c,0x01,0x7b,0x00,0x7c,0xff,0x7b,0xfe,0x7c,
  0xfe,0x7d,0xfe,0x7e,0x02,0x9e,0x02,0x7c,0x01,0x7d,
  0x01,0x7b,0x00,0x7c,0xff,0x7b,0xff,0x7d,0xfe,0x7c,
  0x09,0x85,0x08,0x95,0x00,0x74,0xfb,0x89,0x0a,0x7a,
  0x00,0x86,0xf6,0x7a,0x0d,0xf4,0x0d,0x92,0x00,0x6e,
  0xf7,0x89,0x12,0x00,0x04,0xf7,0x06,0x81,0xff,0x7f,
  0xff,0x01,0x01,0x01,0x01,0x7f,0x00,0x7e,0xff,0x7e,
  0xff,0x7f,0x06,0x84,0x04,0x89,0x12,0x00,0x04,0xf7,
  0x05,0x82,0xff,0x7f,0x01,0x7f,0x01,0x01,0xff,0x01,
  0x05,0xfe,0x00,0xfd,0x0e,0x18,0x00,0xeb,0x09,0x95,
  0xfd,0x7f,0xfe,0x7d,0xff,0x7b,0x00,0x7d,0x01,0x7b,
  0x02,0x7d,0x03,0x7f,0x02,0x00,0x03,0x01,0x02,0x03,
  0x01,0x05,0x00,0x03,0xff,0x05,0xfe,0x03,0xfd,0x01,
  0xfe,0x00,0x0b,0xeb,0x06,0x91,0x02,0x01,0x03,0x03,
  0x00,0x6b,0x09,0x80,0x04,0x90,0x00,0x01,0x01,0x02,
  0x01,0x01,0x02,0x01,0x04,0x00,0x02,0x7f,0x01,0x7f,
  0x01,0x7e,0x00,0x7e,0xff,0x7e,0xfe,0x7d,0xf6,0x76,
  0x0e,0x00,0x03,0x80,0x05,0x95,0x0b,0x00,0xfa,0x78,
  0x03,0x00,0x02,0x7f,0x01,0x7f,0x01,0x7d,0x00,0x7e,
  0xff,0x7d,0xfe,0x7e,0xfd,0x7f,0xfd,0x00,0xfd,0x01,
  0xff,0x01,0xff,0x02,0x11,0xfc,0x0d,0x95,0xf6,0x72,
  0x0f,0x00,0xfb,0x8e,0x00,0x6b,0x07,0x80,0x0f,0x95,
  0xf6,0x00,0xff,0x77,0x01,0x01,0x03,0x01,0x03,0x00,
  0x03,0x7f,0x02,0x7e,0x01,0x7d,0x00,0x7e,0xff,0x7d,
  0xfe,0x7e,0xfd,0x7f,0xfd,0x00,0xfd,0x01,0xff,0x01,
  0xff,0x02,0x11,0xfc,0x10,0x92,0xff,0x02,0xfd,0x01,
  0xfe,0x00,0xfd,0x7f,0xfe,0x7d,0xff,0x7b,0x00,0x7b,
  0x01,0x7c,0x02,0x7e,0x03,0x7f,0x01,0x00,0x03,0x01,
  0x02,0x02,0x01,0x03,0x00,0x01,0xff,0x03,0xfe,0x02,
  0xfd,0x01,0xff,0x00,0xfd,0x7f,0xfe,0x7e,0xff,0x7d,
  0x10,0xf9,0x11,0x95,0xf6,0x6b,0xfc,0x95,0x0e,0x00,
  0x03,0xeb,0x08,0x95,0xfd,0x7f,0xff,0x7e,0x00,0x7e,
  0x01,0x7e,0x02,0x7f,0x04,0x7f,0x03,0x7f,0x02,0x7e,
  0x01,0x7e,0x00,0x7d,0xff,0x7e,0xff,0x7f,0xfd,0x7f,
  0xfc,0x00,0xfd,0x01,0xff,0x01,0xff,0x02,0x00,0x03,
  0x01,0x02,0x02,0x02,0x03,0x01,0x04,0x01,0x02,0x01,
  0x01,0x02,0x00,0x02,0xff,0x02,0xfd,0x01,0xfc,0x00,
  0x0c,0xeb,0x10,0x8e,0xff,0x7d,0xfe,0x7e,0xfd,0x7f,
  0xff,0x00,0xfd,0x01,0xfe,0x02,0xff,0x03,0x00,0x01,
  0x01,0x03,0x02,0x02,0x03,0x01,0x01,0x00,0x03,0x7f,
  0x02,0x7e,0x01,0x7c,0x00,0x7b,0xff,0x7b,0xfe,0x7d,
  0xfd,0x7f,0xfe,0x00,0xfd,0x01,0xff,0x02,0x10,0xfd,
  0x05,0x8e,0xff,0x7f,0x01,0x7f,0x01,0x01,0xff,0x01,
  0x00,0xf4,0xff,0x7f,0x01,0x7f,0x01,0x01,0xff,0x01,
  0x05,0xfe,0x05,0x8e,0xff,0x7f,0x01,0x7f,0x01,0x01,
  0xff,0x01,0x01,0xf3,0xff,0x7f,0xff,0x01,0x01,0x01,
  0x01,0x7f,0x00,0x7e,0xff,0x7e,0xff,0x7f,0x06,0x84,
  0x14,0x92,0xf0,0x77,0x10,0x77,0x04,0x80,0x04,0x8c,
  0x12,0x00,0xee,0xfa,0x12,0x00,0x04,0xfa,0x04,0x92,
  0x10,0x77,0xf0,0x77,0x14,0x80,0x03,0x90,0x00,0x01,
  0x01,0x02,0x01,0x01,0x02,0x01,0x04,0x00,0x02,0x7f,
  0x01,0x7f,0x01,0x7e,0x00,0x7e,0xff,0x7e,0xff,0x7f,
  0xfc,0x7e,0x00,0x7d,0x00,0xfb,0xff,0x7f,0x01,0x7f,
  0x01,0x01,0xff,0x01,0x09,0xfe,0x12,0x8d,0xff,0x02,
  0xfe,0x01,0xfd,0x00,0xfe,0x7f,0xff,0x7f,0xff,0x7d,
  0x00,0x7d,0x01,0x7e,0x02,0x7f,0x03,0x00,0x02,0x01,
  0x01,0x02,0xfb,0x88,0xfe,0x7e,0xff,0x7d,0x00,0x7d,
  0x01,0x7e,0x01,0x7f,0x07,0x8b,0xff,0x78,0x00,0x7e,
  0x02,0x7f,0x02,0x00,0x02,0x02,0x01,0x03,0x00,0x02,
  0xff,0x03,0xff,0x02,0xfe,0x02,0xfe,0x01,0xfd,0x01,
  0xfd,0x00,0xfd,0x7f,0xfe,0x7f,0xfe,0x7e,0xff,0x7e,
  0xff,0x7d,0x00,0x7d,0x01,0x7d,0x01,0x7e,0x02,0x7e,
  0x02,0x7f,0x03,0x7f,0x03,0x00,0x03,0x01,0x02,0x01,
  0x01,0x01,0xfe,0x8d,0xff,0x78,0x00,0x7e,0x01,0x7f,
  0x08,0xfb,0x09,0x95,0xf8,0x6b,0x08,0x95,0x08,0x6b,
  0xf3,0x87,0x0a,0x00,0x04,0xf9,0x04,0x95,0x00,0x6b,
  0x00,0x95,0x09,0x00,0x03,0x7f,0x01,0x7f,0x01,0x7e,
  0x00,0x7e,0xff,0x7e,0xff,0x7f,0xfd,0x7f,0xf7,0x80,
  0x09,0x00,0x03,0x7f,0x01,0x7f,0x01,0x7e,0x00,0x7d,
  0xff,0x7e,0xff,0x7f,0xfd,0x7f,0xf7,0x00,0x11,0x80,
  0x12,0x90,0xff,0x02,0xfe,0x02,0xfe,0x01,0xfc,0x00,
  0xfe,0x7f,0xfe,0x7e,0xff,0x7e,0xff,0x7d,0x00,0x7b,
  0x01,0x7d,0x01,0x7e,0x02,0x7e,0x02,0x7f,0x04,0x00,
  0x02,0x01,0x02,0x02,0x01,0x02,0x03,0xfb,0x04,0x95,
  0x00,0x6b,0x00,0x95,0x07,0x00,0x03,0x7f,0x02,0x7e,
  0x01,0x7e,0x01,0x7d,0x00,0x7b,0xff,0x7d,0xff,0x7e,
  0xfe,0x7e,0xfd,0x7f,0xf9,0x00,0x11,0x80,0x04,0x95,
  0x00,0x6b,0x00,0x95,0x0d,0x00,0xf3,0xf6,0x08,0x00,
  0xf8,0xf5,0x0d,0x00,0x02,0x80,0x04,0x95,0x00,0x6b,
  0x00,0x95,0x0d,0x00,0xf3,0xf6,0x08,0x00,0x06,0xf5,
  0x12,0x90,0xff,0x02,0xfe,0x02,0xfe,0x01,0xfc,0x00,
  0xfe,0x7f,0xfe,0x7e,0xff,0x7e,0xff,0x7d,0x00,0x7b,
  0x01,0x7d,0x01,0x7e,0x02,0x7e,0x02,0x7f,0x04,0x00,
  0x02,0x01,0x02,0x02,0x01,0x02,0x00,0x03,0xfb,0x80,
  0x05,0x00,0x03,0xf8,0x04,0x95,0x00,0x6b,0x0e,0x95,
  0x00,0x6b,0xf2,0x8b,0x0e,0x00,0x04,0xf5,0x04,0x95,
  0x00,0x6b,0x04,0x80,0x0c,0x95,0x00,0x70,0xff,0x7d,
  0xff,0x7f,0xfe,0x7f,0xfe,0x00,0xfe,0x01,0xff,0x01,
  0xff,0x03,0x00,0x02,0x0e,0xf9,0x04,0x95,0x00,0x6b,
  0x0e,0x95,0xf2,0x72,0x05,0x85,0x09,0x74,0x03,0x80,
  0x04,0x95,0x00,0x6b,0x00,0x80,0x0c,0x00,0x01,0x80,
  0x04,0x95,0x00,0x6b,0x00,0x95,0x08,0x6b,0x08,0x95,
  0xf8,0x6b,0x08,0x95,0x00,0x6b,0x04,0x80,0x04,0x95,
  0x00,0x6b,0x00,0x95,0x0e,0x6b,0x00,0x95,0x00,0x6b,
  0x04,0x80,0x09,0x95,0xfe,0x7f,0xfe,0x7e,0xff,0x7e,
  0xff,0x7d,0x00,0x7b,0x01,0x7d,0x01,0x7e,0x02,0x7e,
  0x02,0x7f,0x04,0x00,0x02,0x01,0x02,0x02,0x01,0x02,
  0x01,0x03,0x00,0x05,0xff,0x03,0xff,0x02,0xfe,0x02,
  0xfe,0x01,0xfc,0x00,0x0d,0xeb,0x04,0x95,0x00,0x6b,
  0x00,0x95,0x09,0x00,0x03,0x7f,0x01,0x7f,0x01,0x7e,
  0x00,0x7d,0xff,0x7e,0xff,0x7f,0xfd,0x7f,0xf7,0x00,
  0x11,0xf6,0x09,0x95,0xfe,0x7f,0xfe,0x7e,0xff,0x7e,
  0xff,0x7d,0x00,0x7b,0x01,0x7d,0x01,0x7e,0x02,0x7e,
  0x02,0x7f,0x04,0x00,0x02,0x01,0x02,0x02,0x01,0x02,
  0x01,0x03,0x00,0x05,0xff,0x03,0xff,0x02,0xfe,0x02,
  0xfe,0x01,0xfc,0x00,0x03,0xef,0x06,0x7a,0x04,0x82,
  0x04,0x95,0x00,0x6b,0x00,0x95,0x09,0x00,0x03,0x7f,
  0x01,0x7f,0x01,0x7e,0x00,0x7e,0xff,0x7e,0xff,0x7f,
  0xfd,0x7f,0xf7,0x00,0x07,0x80,0x07,0x75,0x03,0x80,
  0x11,0x92,0xfe,0x02,0xfd,0x01,0xfc,0x00,0xfd,0x7f,
  0xfe,0x7e,0x00,0x7e,0x01,0x7e,0x01,0x7f,0x02,0x7f,
  0x06,0x7e,0x02,0x7f,0x01,0x7f,0x01,0x7e,0x00,0x7d,
  0xfe,0x7e,0xfd,0x7f,0xfc,0x00,0xfd,0x01,0xfe,0x02,
  0x11,0xfd,0x08,0x95,0x00,0x6b,0xf9,0x95,0x0e,0x00,
  0x01,0xeb,0x04,0x95,0x00,0x71,0x01,0x7d,0x02,0x7e,
  0x03,0x7f,0x02,0x00,0x03,0x01,0x02,0x02,0x01,0x03,
  0x00,0x0f,0x04,0xeb,0x01,0x95,0x08,0x6b,0x08,0x95,
  0xf8,0x6b,0x09,0x80,0x02,0x95,0x05,0x6b,0x05,0x95,
  0xfb,0x6b,0x05,0x95,0x05,0x6b,0x05,0x95,0xfb,0x6b,
  0x07,0x80,0x03,0x95,0x0e,0x6b,0x00,0x95,0xf2,0x6b,
  0x11,0x80,0x01,0x95,0x08,0x76,0x00,0x75,0x08,0x95,
  0xf8,0x76,0x09,0xf5,0x11,0x95,0xf2,0x6b,0x00,0x95,
  0x0e,0x00,0xf2,0xeb,0x0e,0x00,0x03,0x80,0x03,0x93,
  0x00,0x6c,0x01,0x94,0x00,0x6c,0xff,0x94,0x05,0x00,
  0xfb,0xec,0x05,0x00,0x02,0x81,0x00,0x95,0x0e,0x68,
  0x00,0x83,0x06,0x93,0x00,0x6c,0x01,0x94,0x00,0x6c,
  0xfb,0x94,0x05,0x00,0xfb,0xec,0x05,0x00,0x03,0x81,
  0x03,0x87,0x08,0x05,0x08,0x7b,0xf0,0x80,0x08,0x04,
  0x08,0x7c,0x03,0xf9,0x01,0x80,0x10,0x00,0x01,0x80,
  0x06,0x95,0xff,0x7f,0xff,0x7e,0x00,0x7e,0x01,0x7f,
  0x01,0x01,0xff,0x01,0x05,0xef,0x0f,0x8e,0x00,0x72,
  0x00,0x8b,0xfe,0x02,0xfe,0x01,0xfd,0x00,0xfe,0x7f,
  0xfe,0x7e,0xff,0x7d,0x00,0x7e,0x01,0x7d,0x02,0x7e,
  0x02,0x7f,0x03,0x00,0x02,0x01,0x02,0x02,0x04,0xfd,
  0x04,0x95,0x00,0x6b,0x00,0x8b,0x02,0x02,0x02,0x01,
  0x03,0x00,0x02,0x7f,0x02,0x7e,0x01,0x7d,0x00,0x7e,
  0xff,0x7d,0xfe,0x7e,0xfe,0x7f,0xfd,0x00,0xfe,0x01,
  0xfe,0x02,0x0f,0xfd,0x0f,0x8b,0xfe,0x02,0xfe,0x01,
  0xfd,0x00,0xfe,0x7f,0xfe,0x7e,0xff,0x7d,0x00,0x7e,
  0x01,0x7d,0x02,0x7e,0x02,0x7f,0x03,0x00,0x02,0x01,
  0x02,0x02,0x03,0xfd,0x0f,0x95,0x00,0x6b,0x00,0x8b,
  0xfe,0x02,0xfe,0x01,0xfd,0x00,0xfe,0x7f,0xfe,0x7e,
  0xff,0x7d,0x00,0x7e,0x01,0x7d,0x02,0x7e,0x02,0x7f,
  0x03,0x00,0x02,0x01,0x02,0x02,0x04,0xfd,0x03,0x88,
  0x0c,0x00,0x00,0x02,0xff,0x02,0xff,0x01,0xfe,0x01,
  0xfd,0x00,0xfe,0x7f,0xfe,0x7e,0xff,0x7d,0x00,0x7e,
  0x01,0x7d,0x02,0x7e,0x02,0x7f,0x03,0x00,0x02,0x01,
  0x02,0x02,0x03,0xfd,0x0a,0x95,0xfe,0x00,0xfe,0x7f,
  0xff,0x7d,0x00,0x6f,0xfd,0x8e,0x07,0x00,0x03,0xf2,
  0x0f,0x8e,0x00,0x70,0xff,0x7d,0xff,0x7f,0xfe,0x7f,
  0xfd,0x00,0xfe,0x01,0x09,0x91,0xfe,0x02,0xfe,0x01,
  0xfd,0x00,0xfe,0x7f,0xfe,0x7e,0xff,0x7d,0x00,0x7e,
  0x01,0x7d,0x02,0x7e,0x02,0x7f,0x03,0x00,0x02,0x01,
  0x02,0x02,0x04,0xfd,0x04,0x95,0x00,0x6b,0x00,0x8a,
  0x03,0x03,0x02,0x01,0x03,0x00,0x02,0x7f,0x01,0x7d,
  0x00,0x76,0x04,0x80,0x03,0x95,0x01,0x7f,0x01,0x01,
  0xff,0x01,0xff,0x7f,0x01,0xf9,0x00,0x72,0x04,0x80,
  0x05,0x95,0x01,0x7f,0x01,0x01,0xff,0x01,0xff,0x7f,
  0x01,0xf9,0x00,0x6f,0xff,0x7d,0xfe,0x7f,0xfe,0x00,
  0x09,0x87,0x04,0x95,0x00,0x6b,0x0a,0x8e,0xf6,0x76,
  0x04,0x84,0x07,0x78,0x02,0x80,0x04,0x95,0x00,0x6b,
  0x04,0x80,0x04,0x8e,0x00,0x72,0x00,0x8a,0x03,0x03,
  0x02,0x01,0x03,0x00,0x02,0x7f,0x01,0x7d,0x00,0x76,
  0x00,0x8a,0x03,0x03,0x02,0x01,0x03,0x00,0x02,0x7f,
  0x01,0x7d,0x00,0x76,0x04,0x80,0x04,0x8e,0x00,0x72,
  0x00,0x8a,0x03,0x03,0x02,0x01,0x03,0x00,0x02,0x7f,
  0x01,0x7d,0x00,0x76,0x04,0x80,0x08,0x8e,0xfe,0x7f,
  0xfe,0x7e,0xff,0x7d,0x00,0x7e,0x01,0x7d,0x02,0x7e,
  0x02,0x7f,0x03,0x00,0x02,0x01,0x02,0x02,0x01,0x03,
  0x00,0x02,0xff,0x03,0xfe,0x02,0xfe,0x01,0xfd,0x00,
  0x0b,0xf2,0x04,0x8e,0x00,0x6b,0x00,0x92,0x02,0x02,
  0x02,0x01,0x03,0x00,0x02,0x7f,0x02,0x7e,0x01,0x7d,
  0x00,0x7e,0xff,0x7d,0xfe,0x7e,0xfe,0x7f,0xfd,0x00,
  0xfe,0x01,0xfe,0x02,0x0f,0xfd,0x0f,0x8e,0x00,0x6b,
  0x00,0x92,0xfe,0x02,0xfe,0x01,0xfd,0x00,0xfe,0x7f,
  0xfe,0x7e,0xff,0x7d,0x00,0x7e,0x01,0x7d,0x02,0x7e,
  0x02,0x7f,0x03,0x00,0x02,0x01,0x02,0x02,0x04,0xfd,
  0x04,0x8e,0x00,0x72,0x00,0x88,0x01,0x03,0x02,0x02,
  0x02,0x01,0x03,0x00,0x01,0xf2,0x0e,0x8b,0xff,0x02,
  0xfd,0x01,0xfd,0x00,0xfd,0x7f,0xff,0x7e,0x01,0x7e,
  0x02,0x7f,0x05,0x7f,0x02,0x7f,0x01,0x7e,0x00,0x7f,
  0xff,0x7e,0xfd,0x7f,0xfd,0x00,0xfd,0x01,0xff,0x02,
  0x0e,0xfd,0x05,0x95,0x00,0x6f,0x01,0x7d,0x02,0x7f,
  0x02,0x00,0xf8,0x8e,0x07,0x00,0x03,0xf2,0x04,0x8e,
  0x00,0x76,0x01,0x7d,0x02,0x7f,0x03,0x00,0x02,0x01,
  0x03,0x03,0x00,0x8a,0x00,0x72,0x04,0x80,0x02,0x8e,
  0x06,0x72,0x06,0x8e,0xfa,0x72,0x08,0x80,0x03,0x8e,
  0x04,0x72,0x04,0x8e,0xfc,0x72,0x04,0x8e,0x04,0x72,
  0x04,0x8e,0xfc,0x72,0x07,0x80,0x03,0x8e,0x0b,0x72,
  0x00,0x8e,0xf5,0x72,0x0e,0x80,0x02,0x8e,0x06,0x72,
  0x06,0x8e,0xfa,0x72,0xfe,0x7c,0xfe,0x7e,0xfe,0x7f,
  0xff,0x00,0x0f,0x87,0x0e,0x8e,0xf5,0x72,0x00,0x8e,
  0x0b,0x00,0xf5,0xf2,0x0b,0x00,0x03,0x80,0x09,0x99,
  0xfe,0x7f,0xff,0x7f,0xff,0x7e,0x00,0x7e,0x01,0x7e,
  0x01,0x7f,0x01,0x7e,0x00,0x7e,0xfe,0x7e,0x01,0x8e,
  0xff,0x7e,0x00,0x7e,0x01,0x7e,0x01,0x7f,0x01,0x7e,
  0x00,0x7e,0xff,0x7e,0xfc,0x7e,0x04,0x7e,0x01,0x7e,
  0x00,0x7e,0xff,0x7e,0xff,0x7f,0xff,0x7e,0x00,0x7e,
  0x01,0x7e,0xff,0x8e,0x02,0x7e,0x00,0x7e,0xff,0x7e,
  0xff,0x7f,0xff,0x7e,0x00,0x7e,0x01,0x7e,0x01,0x7f,
  0x02,0x7f,0x05,0x87,0x04,0x95,0x00,0x77,0x00,0xfd,
  0x00,0x77,0x04,0x80,0x05,0x99,0x02,0x7f,0x01,0x7f,
  0x01,0x7e,0x00,0x7e,0xff,0x7e,0xff,0x7f,0xff,0x7e,
  0x00,0x7e,0x02,0x7e,0xff,0x8e,0x01,0x7e,0x00,0x7e,
  0xff,0x7e,0xff,0x7f,0xff,0x7e,0x00,0x7e,0x01,0x7e,
  0x04,0x7e,0xfc,0x7e,0xff,0x7e,0x00,0x7e,0x01,0x7e,
  0x01,0x7f,0x01,0x7e,0x00,0x7e,0xff,0x7e,0x01,0x8e,
  0xfe,0x7e,0x00,0x7e,0x01,0x7e,0x01,0x7f,0x01,0x7e,
  0x00,0x7e,0xff,0x7e,0xff,0x7f,0xfe,0x7f,0x09,0x87,
  0x03,0x86,0x00,0x02,0x01,0x03,0x02,0x01,0x02,0x00,
  0x02,0x7f,0x04,0x7d,0x02,0x7f,0x02,0x00,0x02,0x01,
  0x01,0x02,0xee,0xfe,0x01,0x02,0x02,0x01,0x02,0x00,
  0x02,0x7f,0x04,0x7d,0x02,0x7f,0x02,0x00,0x02,0x01,
  0x01,0x03,0x00,0x02,0x03,0xf4,0x10,0x80,0x03,0x80,
  0x07,0x15,0x08,0x6b,0xfe,0x85,0xf5,0x00,0x10,0xfb,
  0x0d,0x95,0xf6,0x00,0x00,0x6b,0x0a,0x00,0x02,0x02,
  0x00,0x08,0xfe,0x02,0xf6,0x00,0x0e,0xf4,0x03,0x80,
  0x00,0x15,0x0a,0x00,0x02,0x7e,0x00,0x7e,0x00,0x7d,
  0x00,0x7e,0xfe,0x7f,0xf6,0x00,0x0a,0x80,0x02,0x7e,
  0x01,0x7e,0x00,0x7d,0xff,0x7d,0xfe,0x7f,0xf6,0x00,
  0x10,0x80,0x03,0x80,0x00,0x15,0x0c,0x00,0xff,0x7e,
  0x03,0xed,0x03,0xfd,0x00,0x03,0x02,0x00,0x00,0x12,
  0x02,0x03,0x0a,0x00,0x00,0x6b,0x02,0x00,0x00,0x7d,
  0xfe,0x83,0xf4,0x00,0x11,0x80,0x0f,0x80,0xf4,0x00,
  0x00,0x15,0x0c,0x00,0xff,0xf6,0xf5,0x00,0x0f,0xf5,
  0x04,0x95,0x07,0x76,0x00,0x0a,0x07,0x80,0xf9,0x76,
  0x00,0x75,0xf8,0x80,0x07,0x0c,0x09,0xf4,0xf9,0x0c,
  0x09,0xf4,0x03,0x92,0x02,0x03,0x07,0x00,0x03,0x7d,
  0x00,0x7b,0xfc,0x7e,0x04,0x7d,0x00,0x7a,0xfd,0x7e,
  0xf9,0x00,0xfe,0x02,0x06,0x89,0x02,0x00,0x06,0xf5,
  0x03,0x95,0x00,0x6b,0x0c,0x15,0x00,0x6b,0x02,0x80,
  0x03,0x95,0x00,0x6b,0x0c,0x15,0x00,0x6b,0xf8,0x96,
  0x03,0x00,0x07,0xea,0x03,0x80,0x00,0x15,0x0c,0x80,
  0xf7,0x76,0xfd,0x00,0x03,0x80,0x0a,0x75,0x03,0x80,
  0x03,0x80,0x07,0x13,0x02,0x02,0x03,0x00,0x00,0x6b,
  0x02,0x80,0x03,0x80,0x00,0x15,0x09,0x6b,0x09,0x15,
  0x00,0x6b,0x03,0x80,0x03,0x80,0x00,0x15,0x00,0xf6,
  0x0d,0x00,0x00,0x8a,0x00,0x6b,0x03,0x80,0x07,0x80,
  0xfd,0x00,0xff,0x03,0x00,0x04,0x00,0x07,0x00,0x04,
  0x01,0x02,0x03,0x01,0x06,0x00,0x03,0x7f,0x01,0x7e,
  0x01,0x7c,0x00,0x79,0xff,0x7c,0xff,0x7d,0xfd,0x00,
  0xfa,0x00,0x0e,0x80,0x03,0x80,0x00,0x15,0x0c,0x00,
  0x00,0x6b,0x02,0x80,0x03,0x80,0x00,0x15,0x0a,0x00,
  0x02,0x7f,0x01,0x7d,0x00,0x7b,0xff,0x7e,0xfe,0x7f,
  0xf6,0x00,0x10,0xf7,0x11,0x8f,0xff,0x03,0xff,0x02,
  0xfe,0x01,0xfa,0x00,0xfd,0x7f,0xff,0x7e,0x00,0x7c,
  0x00,0x79,0x00,0x7b,0x01,0x7e,0x03,0x00,0x06,0x00,
  0x02,0x00,0x01,0x03,0x01,0x02,0x03,0xfb,0x03,0x95,
  0x0c,0x00,0xfa,0x80,0x00,0x6b,0x09,0x80,0x03,0x95,
  0x00,0x77,0x06,0x7a,0x06,0x06,0x00,0x09,0xfa,0xf1,
  0xfa,0x7a,0x0e,0x80,0x03,0x87,0x00,0x0b,0x02,0x02,
  0x03,0x00,0x02,0x7e,0x01,0x02,0x04,0x00,0x02,0x7e,
  0x00,0x75,0xfe,0x7e,0xfc,0x00,0xff,0x01,0xfe,0x7f,
  0xfd,0x00,0xfe,0x02,0x07,0x8e,0x00,0x6b,0x09,0x80,
  0x03,0x80,0x0e,0x15,0xf2,0x80,0x0e,0x6b,0x03,0x80,
  0x03,0x95,0x00,0x6b,0x0e,0x00,0x00,0x7d,0xfe,0x98,
  0x00,0x6b,0x05,0x80,0x03,0x95,0x00,0x75,0x02,0x7d,
  0x0a,0x00,0x00,0x8e,0x00,0x6b,0x02,0x80,0x03,0x95,
  0x00,0x6b,0x10,0x00,0x00,0x15,0xf8,0x80,0x00,0x6b,
  0x0a,0x80,0x03,0x95,0x00,0x6b,0x10,0x00,0x00,0x15,
  0xf8,0x80,0x00,0x6b,0x0a,0x00,0x00,0x7d,0x02,0x83,
  0x10,0x80,0x03,0x95,0x00,0x6b,0x09,0x00,0x03,0x02,
  0x00,0x08,0xfd,0x02,0xf7,0x00,0x0e,0x89,0x00,0x6b,
  0x03,0x80,0x03,0x95,0x00,0x6b,0x09,0x00,0x03,0x02,
  0x00,0x08,0xfd,0x02,0xf7,0x00,0x0e,0xf4,0x03,0x92,
  0x02,0x03,0x07,0x00,0x03,0x7d,0x00,0x70,0xfd,0x7e,
  0xf9,0x00,0xfe,0x02,0x03,0x89,0x09,0x00,0x02,0xf5,
  0x03,0x80,0x00,0x15,0x00,0xf5,0x07,0x00,0x00,0x08,
  0x02,0x03,0x06,0x00,0x02,0x7d,0x00,0x70,0xfe,0x7e,
  0xfa,0x00,0xfe,0x02,0x00,0x08,0x0c,0xf6,0x0f,0x80,
  0x00,0x15,0xf6,0x00,0xfe,0x7d,0x00,0x79,0x02,0x7e,
  0x0a,0x00,0xf4,0xf7,0x07,0x09,0x07,0xf7,0x03,0x8c,
  0x01,0x02,0x01,0x01,0x05,0x00,0x02,0x7f,0x01,0x7e,
  0x00,0x74,0x00,0x86,0xff,0x01,0xfe,0x01,0xfb,0x00,
  0xff,0x7f,0xff,0x7f,0x00,0x7c,0x01,0x7e,0x01,0x00,
  0x05,0x00,0x02,0x00,0x01,0x02,0x03,0xfe,0x04,0x8e,
  0x02,0x01,0x04,0x00,0x02,0x7f,0x01,0x7e,0x00,0x77,
  0xff,0x7e,0xfe,0x7f,0xfc,0x00,0xfe,0x01,0xff,0x02,
  0x00,0x09,0x01,0x02,0x02,0x02,0x03,0x01,0x02,0x01,
  0x01,0x01,0x01,0x02,0x02,0xeb,0x03,0x80,0x00,0x15,
  0x03,0x00,0x02,0x7e,0x00,0x7b,0xfe,0x7e,0xfd,0x00,
  0x03,0x80,0x04,0x00,0x03,0x7e,0x00,0x78,0xfd,0x7e,
  0xf9,0x00,0x0c,0x80,0x03,0x8c,0x02,0x02,0x02,0x01,
  0x03,0x00,0x02,0x7f,0x01,0x7d,0xfe,0x7e,0xf9,0x7d,
  0xff,0x7e,0x00,0x7d,0x03,0x7f,0x02,0x00,0x03,0x01,
  0x02,0x01,0x02,0xfe,0x0d,0x8c,0xff,0x02,0xfe,0x01,
  0xfc,0x00,0xfe,0x7f,0xff,0x7e,0x00,0x77,0x01,0x7e,
  0x02,0x7f,0x04,0x00,0x02,0x01,0x01,0x02,0x00,0x0f,
  0xff,0x02,0xfe,0x01,0xf9,0x00,0x0c,0xeb,0x03,0x88,
  0x0a,0x00,0x00,0x02,0x00,0x03,0xfe,0x02,0xfa,0x00,
  0xff,0x7e,0xff,0x7d,0x00,0x7b,0x01,0x7c,0x01,0x7f,
  0x06,0x00,0x02,0x02,0x03,0xfe,0x03,0x8f,0x06,0x77,
  0x06,0x09,0xfa,0x80,0x00,0x71,0xff,0x87,0xfb,0x79,
  0x07,0x87,0x05,0x79,0x02,0x80,0x03,0x8d,0x02,0x02,
  0x06,0x00,0x02,0x7e,0x00,0x7d,0xfc,0x7d,0x04,0x7e,
  0x00,0x7d,0xfe,0x7e,0xfa,0x00,0xfe,0x02,0x04,0x85,
  0x02,0x00,0x06,0xf9,0x03,0x8f,0x00,0x73,0x01,0x7e,
  0x07,0x00,0x02,0x02,0x00,0x0d,0x00,0xf3,0x01,0x7e,
  0x03,0x80,0x03,0x8f,0x00,0x73,0x01,0x7e,0x07,0x00,
  0x02,0x02,0x00,0x0d,0x00,0xf3,0x01,0x7e,0xf8,0x90,
  0x03,0x00,0x08,0xf0,0x03,0x80,0x00,0x15,0x00,0xf3,
  0x02,0x00,0x06,0x07,0xfa,0xf9,0x07,0x78,0x03,0x80,
  0x03,0x80,0x04,0x0c,0x02,0x03,0x04,0x00,0x00,0x71,
  0x02,0x80,0x03,0x80,0x00,0x0f,0x06,0x77,0x06,0x09,
  0x00,0x71,0x02,0x80,0x03,0x80,0x00,0x0f,0x0a,0xf1,
  0x00,0x0f,0xf6,0xf8,0x0a,0x00,0x02,0xf9,0x05,0x80,
  0xff,0x01,0xff,0x04,0x00,0x05,0x01,0x03,0x01,0x02,
  0x06,0x00,0x02,0x7e,0x00,0x7d,0x00,0x7b,0x00,0x7c,
  0xfe,0x7f,0xfa,0x00,0x0b,0x80,0x03,0x80,0x00,0x0f,
  0x00,0xfb,0x01,0x03,0x01,0x02,0x05,0x00,0x02,0x7e,
  0x01,0x7d,0x00,0x76,0x03,0x80,0x10,0x80,0x10,0x80,
  0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,
  0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,
  0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,
  0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,
  0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,
  0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,
  0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,
  0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,
  0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,0x10,0x80,
  0x10,0x80,0x0a,0x8f,0x02,0x7f,0x01,0x7e,0x00,0x76,
  0xff,0x7f,0xfe,0x7f,0xfb,0x00,0xff,0x01,0xff,0x01,
  0x00,0x0a,0x01,0x02,0x01,0x01,0x05,0x00,0xf9,0x80,
  0x00,0x6b,0x0c,0x86,0x0d,0x8a,0xff,0x03,0xfe,0x02,
  0xfb,0x00,0xff,0x7e,0xff,0x7d,0x00,0x7b,0x01,0x7c,
  0x01,0x7f,0x05,0x00,0x02,0x01,0x01,0x03,0x03,0xfc,
  0x03,0x80,0x00,0x0f,0x00,0xfb,0x01,0x03,0x01,0x02,
  0x04,0x00,0x01,0x7e,0x01,0x7d,0x00,0x76,0x00,0x8a,
  0x01,0x03,0x02,0x02,0x03,0x00,0x02,0x7e,0x01,0x7d,
  0x00,0x76,0x03,0x80,0x03,0x8f,0x00,0x74,0x01,0x7e,
  0x02,0x7f,0x04,0x00,0x02,0x01,0x01,0x01,0x00,0x8d,
  0x00,0x6e,0xff,0x7e,0xfe,0x7f,0xfb,0x00,0xfe,0x01,
  0x0c,0x85,0x03,0x8d,0x01,0x02,0x03,0x00,0x02,0x7e,
  0x01,0x02,0x03,0x00,0x02,0x7e,0x00,0x74,0xfe,0x7f,
  0xfd,0x00,0xff,0x01,0xfe,0x7f,0xfd,0x00,0xff,0x01,
  0x00,0x0c,0x06,0x82,0x00,0x6b,0x08,0x86,0x03,0x80,
  0x0a,0x0f,0xf6,0x80,0x0a,0x71,0x03,0x80,0x03,0x8f,
  0x00,0x73,0x01,0x7e,0x07,0x00,0x02,0x02,0x00,0x0d,
  0x00,0xf3,0x01,0x7e,0x00,0x7e,0x03,0x82,0x03,0x8f,
  0x00,0x79,0x02,0x7e,0x08,0x00,0x00,0x89,0x00,0x71,
  0x02,0x80,0x03,0x8f,0x00,0x73,0x01,0x7e,0x03,0x00,
  0x02,0x02,0x00,0x0d,0x00,0xf3,0x01,0x7e,0x03,0x00,
  0x02,0x02,0x00,0x0d,0x00,0xf3,0x01,0x7e,0x03,0x80,
  0x03,0x8f,0x00,0x73,0x01,0x7e,0x03,0x00,0x02,0x02,
  0x00,0x0d,0x00,0xf3,0x01,0x7e,0x03,0x00,0x02,0x02,
  0x00,0x0d,0x00,0xf3,0x01,0x7e,0x00,0x7e,0x03,0x82,
  0x03,0x8d,0x00,0x02,0x02,0x00,0x00,0x71,0x08,0x00,
  0x02,0x02,0x00,0x06,0xfe,0x02,0xf8,0x00,0x0c,0xf6,
  0x03,0x8f,0x00,0x71,0x07,0x00,0x02,0x02,0x00,0x06,
  0xfe,0x02,0xf9,0x00,0x0c,0x85,0x00,0x71,0x02,0x80,
  0x03,0x8f,0x00,0x71,0x07,0x00,0x03,0x02,0x00,0x06,
  0xfd,0x02,0xf9,0x00,0x0c,0xf6,0x03,0x8d,0x02,0x02,
  0x06,0x00,0x02,0x7e,0x00,0x75,0xfe,0x7e,0xfa,0x00,
  0xfe,0x02,0x04,0x85,0x06,0x00,0x02,0xf9,0x03,0x80,
  0x00,0x0f,0x00,0xf8,0x04,0x00,0x00,0x06,0x02,0x02,
  0x04,0x00,0x02,0x7e,0x00,0x75,0xfe,0x7e,0xfc,0x00,
  0xfe,0x02,0x00,0x05,0x0a,0xf9,0x0d,0x80,0x00,0x0f,
  0xf7,0x00,0xff,0x7e,0x00,0x7b,0x01,0x7e,0x09,0x00,
  0xf6,0xfa,0x04,0x06,0x08,0xfa]

type
  Status = enum
    initial
    nextChar
    startGlyph
    glyph

  GsvText* = object
    mX, mY, mStartX, mWidth, mHeight: float64
    mSpace, mLineSpace: float64
    mChr: array[2, char]
    mText: cstring
    mTextBuf: string
    mCurChar: ptr char
    mFont: pointer
    mLoadedFont: string
    mStatus: Status
    mFlip: bool
    mIndices, mGlyphs, mBGlyph, mEGlyph: ptr uint8
    mW, mH: float64

proc value(p: ptr uint8): uint16 =
  when system.cpuEndian == littleEndian:
    result = p[1].uint16 shl 8
    result = result or p[0].uint16
  else:
    result = p[0].uint16 shl 8
    result = result or p[1].uint16

proc initGsvText*(): GsvText =
  result.mX = 0.0
  result.mY = 0.0
  result.mStartX = 0.0
  result.mWidth = 10.0
  result.mHeight = 0.0
  result.mSpace = 0.0
  result.mLineSpace = 0.0
  result.mText = result.mChr[0].addr
  result.mTextBuf = ""
  result.mCurChar = result.mChr[0].addr
  result.mFont = gsv_default_font[0].addr
  result.mLoadedFont = ""
  result.mStatus = initial
  result.mFlip = false
  result.mChr[0] = 0.chr
  result.mChr[1] = 0.chr

proc font*(self: var GsvText, font: pointer) =
  self.mFont = font
  if self.mFont == nil: self.mFont = self.mLoadedFont[0].addr

proc size*(self: var GsvText, height: float64, width = 0.0'f64) =
  self.mHeight = height
  self.mWidth  = width

proc space*(self: var GsvText, space: float64) =
  self.mSpace = space

proc lineSpace*(self: var GsvText, lineSpace: float64) =
  self.mLineSpace = lineSpace

proc startPoint*(self: var GsvText, x, y: float64) =
  self.mX = x
  self.mStartX = x
  self.mY = y

proc loadFont*(self: var GsvText, file: string) =
  self.mLoadedFont = readFile(file)
  self.mFont = self.mLoadedFont[0].addr

proc text*(self: var GsvText, text: string) =
  if text.len == 0:
    self.mChr[0] = 0.chr
    self.mText = self.mChr[0].addr
    return

  self.mTextBuf = text
  self.mText = self.mTextBuf[0].addr

proc rewind*(self: var GsvText, pathId: int) =
  self.mStatus = initial
  if self.mFont == nil: return

  self.mIndices = cast[ptr uint8](self.mFont)
  var baseHeight = value(self.mIndices + 4).float64
  inc(self.mIndices, value(self.mIndices).int)
  self.mGlyphs = cast[ptr uint8](self.mIndices + 257*2)
  self.mH = self.mHeight / baseHeight
  self.mW = if self.mWidth == 0.0: self.mH else: self.mWidth / baseHeight
  if self.mFlip: self.mH = -self.mH
  self.mCurChar = self.mText[0].addr

proc vertex*(self: var GsvText, x, y: var float64): uint =
  var
    idx: int
    yc, yf: int8
    dx, dy: int

  while true:
    case self.mStatus
    of initial:
      if self.mFont == nil:
        break
      self.mStatus = nextChar
    of nextChar:
      if self.mCurChar[] == 0.chr:
        break

      idx = self.mCurChar[].int and 0xFF
      inc self.mCurChar
      if idx.chr in NewLines:
        self.mX = self.mStartX
        if self.mFlip:
          self.mY -= -self.mHeight - self.mLineSpace
        else:
          self.mY -= self.mHeight + self.mLineSpace
        continue

      idx = idx shl 1
      self.mBGlyph = self.mGlyphs + value(self.mIndices + idx).int
      self.mEGlyph = self.mGlyphs + value(self.mIndices + idx + 2).int
      self.mStatus = startGlyph
    of startGlyph:
      x = self.mX
      y = self.mY
      self.mStatus = glyph
      return pathCmdMoveTo
    of glyph:
      if self.mBGlyph >= self.mEGlyph:
        self.mStatus = nextChar
        self.mX += self.mSpace
        continue

      dx = cast[int8](self.mBglyph[]).int
      inc self.mBglyph
      yc = cast[int8](self.mBglyph[])
      yf = yc and 0x80'i8
      inc self.mBglyph

      yc = yc shl 1
      yc = yc shr 1

      dy = int(yc)
      self.mX += float64(dx) * self.mW
      self.mY += float64(dy) * self.mH
      x = self.mX
      y = self.mY
      return if yf != 0: pathCmdMoveTo else: pathCmdLineTo
    else:
      discard
  result = pathCmdStop

proc textWidth*(self: var GsvText): float64 =
  var x1, y1, x2, y2: float64
  discard self.boundingRectSingle(0, x1, y1, x2, y2)
  result = x2 - x1

type
  GsvTextOutline*[Transformer] = object
    poly: ConvStroke[GsvText, NullMarkers]
    trans: ConvTransform[ConvStroke[GsvText, NullMarkers], Transformer]

proc initGsvTextOutline*[T](text: var GsvText, trans: var T): GsvTextOutline[T] =
  result.poly = initConvStroke[GsvText](text)
  result.trans = initConvTransform(result.poly, trans)

proc width*[T](self: var GsvTextOutline[T], w: float64)  =
  self.poly.width(w)

proc transformer*[T](self: var GsvTextOutline[T], trans: var T) =
  self.trans.transformer(trans)

proc rewind*[T](self: var GsvTextOutline[T], pathId: int) =
  self.trans.rewind(pathId)
  self.poly.lineJoin(roundJoin)
  self.poly.lineCap(roundCap)

proc vertex*[T](self: var GsvTextOutline[T], x, y: var float64): uint =
  result = self.trans.vertex(x, y)
