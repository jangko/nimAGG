import agg_basics

type
  RowAccessor*[T] = object
    buf: ptr T    # Pointer to rendering buffer
    start: ptr T  # Pointer to first pixel depending on stride
    width: uint    # Width in pixels
    height: uint   # Height in pixels
    stride: int   # Number of bytes per row. Can be < 0

  RowPtrCache*[T] = object
    buf: ptr T       # Pointer to rendering buffer
    rows: seq[ptr T] # Pointers to each row of the buffer
    width: uint       # Width in pixels
    height: uint      # Height in pixels
    stride: int      # Number of bytes per row. Can be < 0

  RenderingBuffer* = RowAccessor[uint8]
  RenderingBufferCache* = RowPtrCache[uint8]

proc attach*[T](self: var RowAccessor[T], buf: ptr T, width, height: uint, stride: int) =
  self.buf = buf
  self.start = buf
  self.width = width
  self.height = height
  self.stride = stride
  if stride < 0:
    self.start = self.buf - int(height - 1) * stride

proc initRowAccessor*[T](buf: ptr T, width, height: uint, stride: int): RowAccessor[T] =
  result.buf = nil
  result.start = nil
  result.width = 0
  result.height = 0
  result.stride = 0
  result.attach(buf, width, height, stride)

proc rowPtr*[T](self: RowAccessor[T], y: int): ptr T {.inline.} =
  result = self.start + y * self.stride

proc rowPtr*[T](self: RowAccessor[T], x, y: int, z: int): ptr T {.inline.} =
  result = self.start + y * self.stride
  
proc width*[T](self: RowAccessor[T]): int {.inline.} =
  result = self.width.int

proc height*[T](self: RowAccessor[T]): int {.inline.} =
  result = self.height.int
  
#[

        //--------------------------------------------------------------------
        AGG_INLINE       T* buf()          { return m_buf;    }
        AGG_INLINE const T* buf()    const { return m_buf;    }
        AGG_INLINE unsigned width()  const { return m_width;  }
        AGG_INLINE unsigned height() const { return m_height; }
        AGG_INLINE int      stride() const { return m_stride; }
        AGG_INLINE unsigned stride_abs() const
        {
            return (m_stride < 0) ? unsigned(-m_stride) : unsigned(m_stride);
        }

        //--------------------------------------------------------------------

        AGG_INLINE       T* row_ptr(int y)       { return m_start + y * m_stride; }
        AGG_INLINE const T* row_ptr(int y) const { return m_start + y * m_stride; }
        AGG_INLINE row_data row    (int y) const
        {
            return row_data(0, m_width-1, row_ptr(y));
        }

        //--------------------------------------------------------------------
        template<class RenBuf>
        void copy_from(const RenBuf& src)
        {
            unsigned h = height();
            if(src.height() < h) h = src.height();

            unsigned l = stride_abs();
            if(src.stride_abs() < l) l = src.stride_abs();

            l *= sizeof(T);

            unsigned y;
            unsigned w = width();
            for (y = 0; y < h; y++)
            {
                memcpy(row_ptr(0, y, w), src.row_ptr(y), l);
            }
        }

        //--------------------------------------------------------------------
        void clear(T value)
        {
            unsigned y;
            unsigned w = width();
            unsigned stride = stride_abs();
            for(y = 0; y < height(); y++)
            {
                T* p = row_ptr(0, y, w);
                unsigned x;
                for(x = 0; x < stride; x++)
                {
                    *p++ = value;
                }
            }
        }
]#