#******************************************************************************
# ALX - Skies of Arcadia Legends Examiner
# Copyright (C) 2024 Marcel Renner
# 
# This file is part of ALX.
# 
# ALX is free software: you can redistribute it and/or modify it under the 
# terms of the GNU General Public License as published by the Free Software 
# Foundation, either version 3 of the License, or (at your option) any later 
# version.
# 
# ALX is distributed in the hope that it will be useful, but WITHOUT ANY 
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more 
# details.
# 
# You should have received a copy of the GNU General Public License along 
# with ALX.  If not, see <http://www.gnu.org/licenses/>.
#******************************************************************************

#==============================================================================
#                                 REQUIREMENTS
#==============================================================================

require_relative('aklzfile.rb')
require_relative('bnrfile.rb')
require_relative('compressedfile.rb')
require_relative('fileable.rb')
require_relative('hdrfile.rb')
require_relative('ipfile.rb')

# -- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --

module ALX

#==============================================================================
#                                    CLASS
#==============================================================================

# Class to handle a game root.
class Root

#==============================================================================
#                                   INCLUDES
#==============================================================================

  include(Fileable)
  
#==============================================================================
#                                  CONSTANTS
#==============================================================================

  # Platforms for validation
  PLATFORMS = {
    'DC' => 'Dreamcast',
    'GC' => 'GameCube' ,
  }
  # Countries for validation
  COUNTRIES = ['EU', 'JP', 'US']

#==============================================================================
#                                   PUBLIC
#==============================================================================

  public

  # Constructs a Root.
  def initialize
    clear
  end

  # Initializes the Root.
  def self.init
    @@initialized ||= false
    if @@initialized
      return @@initialized
    end

    ALX.send(:remove_const, self.name.split('::').last)
    ALX.send(:const_set   , self.name.split('::').last, self.new)
    
    @@initialized = true
  end
  
  # Clears all attributes to their default values.
  def clear
    @dirname         = ''
    @luid            = ''
    @platform_id     = ''
    @platform_name   = ''
    @product_id      = ''
    @product_name    = ''
    @product_version = ''
    @product_date    = ''
    @region_id       = ''
    @region_name     = ''
    @country_id      = ''
    @maker_id        = ''
    @maker_name      = ''
    @description     = ''
    @valid           = false
    @etc_resolver    = []
    @etc_cache       = {}
  end
  
  # Reads the game root directory. Returns +true+ if everything is valid, 
  # otherwise +false+.
  # @param _dirname [String] Directory name
  # @return [Boolean] Returns +true+ if everything is valid, otherwise +false+.
  def load(_dirname)
    clear

    _result   = true
    _result &&= init_dir(_dirname)
    _result &&= init_config
    _result &&= init_platform
    
    case @platform_id
    when 'DC'
      _result &&= init_ip
    when 'GC'
      _result &&= init_bnr
      _result &&= init_hdr
    end

    @valid = _result
  end
  
  # Returns +true+ if the game root directory is valid, otherwise +false+.
  # @return [Boolean] +true+ if game root directory is valid, otherwise 
  #                   +false+.
  def valid?
    @valid
  end

  # Returns +true+ if the platform is a Dreamcast, otherwise +false+.
  # @return [Boolean] +true+ if platform is a Dreamcast, otherwise +false+.
  def dc?
    @platform_id == 'DC'
  end

  # Returns +true+ if the platform is a GameCube, otherwise +false+.
  # @return [Boolean] +true+ if platform is a GameCube, otherwise +false+.
  def gc?
    @platform_id == 'GC'
  end

  # Returns +true+ if the country is 'EU', otherwise +false+.
  # @return [Boolean] +true+ if country is 'EU', otherwise +false+.
  def eu?
    @country_id == 'EU'
  end

  # Returns +true+ if the country is 'JP', otherwise +false+.
  # @return [Boolean] +true+ if country is 'JP', otherwise +false+.
  def jp?
    @country_id == 'JP'
  end

  # Returns +true+ if the country is 'US', otherwise +false+.
  # @return [Boolean] +true+ if country is 'US', otherwise +false+.
  def us?
    @country_id == 'US'
  end

  # Returns +:be+ or +:le+ depending on the platform endianness.
  # @return [Symbol] +:big+ or +:little+ depending on endianness.
  def endianness
    cfg(:platform_endianness)
  end

  # Returns +true+ if the endianness is big-endian, otherwise +false+.
  # @return [Boolean] +true+ if endianness is big-endian, otherwise +false+.
  def big_endian?
    endianness == :be
  end

  # Returns +true+ if the endianness is little-endian, otherwise +false+.
  # @return [Boolean] +true+ if endianness is little-endian, otherwise +false+.
  def little_endian?
    endianness == :le
  end

  # Returns the file class depending on +CFG.platform_compressions+. 
  # @return [Class] File class depending on +CFG.platform_compressions+
  def compression
    Kernel.const_get(cfg(:platform_compressions))
  end

  # Returns the value of a ETC attribute. If the value is a Hash, the 
  # instance variables are considered during key selection.
  # 
  # @param _etc [ETC]    ETC object
  # @param _sym [Symbol] ETC attribute symbol
  # @param _ext [String] Extension key which is considered during key 
  #                      selection.
  # 
  # @return [Object] ETC attribute object
  def etc(_etc, _sym, _ext = '*')
    _attr = _etc.send(_sym)
    
    if _attr.is_a?(Hash)
      _cache_id = [_etc, _sym, _ext]
      _key      = @etc_cache[_cache_id]

      if _key
        _value = _attr[_key]
      else
        _value = nil
      end
      if _ext != '*'
        _etc_attr_ext = [_ext]
      else
        _etc_attr_ext = []
      end

      unless _value
        (0...@etc_resolver.size).to_a.reverse.each do |_end|
          _key   = (@etc_resolver[0.._end] + _etc_attr_ext).join('-')
          _value = _attr[_key]

          if _value
            break
          end
        end
        
        unless _value
          _key   = _ext
          _value = _attr[_key]
        end

        if _value
          @etc_cache[_cache_id] = _key
        end
      end

      _attr = _value
    end

    _attr
  end

  # Returns the value of a CFG attribute. If the value is a Hash, the 
  # instance variables are considered during key selection.
  # 
  # @param _sym  [Symbol] CFG attribute symbol
  # @param _keys [String] Additional keys which are considered during key 
  #                       selection.
  # 
  # @return [Object] CFG attribute object
  def cfg(_sym, *_keys)
    etc(CFG, _sym, *_keys)
  end

  # Returns the value of a DSCRPTR attribute. If the value is a Hash, the 
  # instance variables are considered during key selection.
  # 
  # @param _sym  [Symbol] DSCRPTR attribute symbol
  # @param _keys [String] Additional keys which are considered during key 
  #                       selection.
  # 
  # @return [Object] DSCRPTR attribute object
  def dscrptr(_sym, *_keys)
    etc(DSCRPTR, _sym, *_keys)
  end

  # Returns the value of a STRDETR attribute. If the value is a Hash, the 
  # instance variables are considered during key selection.
  # 
  # @param _sym  [Symbol] STRDETR attribute symbol
  # @param _keys [String] Additional keys which are considered during key 
  #                       selection.
  # 
  # @return [Object] STRDETR attribute object
  def strdetr(_sym, *_keys)
    etc(STRDETR, _sym, *_keys)
  end

  # Returns the value of a VOC attribute. If the value is a Hash, the 
  # instance variables are considered during key selection.
  # 
  # @param _sym  [Symbol] VOC attribute symbol
  # @param _keys [String] Additional keys which are considered during key 
  #                       selection.
  # 
  # @return [Object] CFG attribute object
  def voc(_sym, *_keys)
    etc(VOC, _sym, *_keys)
  end
  
  # Returns a new path formed by joining the strings using '/' relative to 
  # #dir. CFG symbols are resolved as well. If they contain a Hash, the game 
  # root attributes are considered during key selection.
  # 
  # @param _args [String,Symbol] Paths or CFG symbols
  # @return [String] Path
  # @see ::File::join
  def join(*_args)
    _paths = _args.collect do |_p|
      _p.is_a?(Symbol) ? cfg(_p) : _p
    end
    File.join(@dirname, *_paths)
  end
  
  # Expands glob pattern and returns a path of the first matching file or 
  # directory relative to #dir. CFG symbols are resolved as well. If they 
  # contain a Hash, the game root attributes are considered during key 
  # selection.
  # 
  # If a block is specified, calls the block once for each matching file or 
  # directory, passing the path as a parameter to the block. 
  # 
  # @param _args [String,Symbol] Glob patterns or CFG attributes
  # @return [String] First matching path
  # @see ::Dir::glob
  def glob(*_args)
    _path  = join(*_args)
    _files = Dir.glob(_path)

    if block_given?
      _files.each_with_index do |_p|
        yield _p
      end
    else
      if _files.empty?
        _path
      else
        _files.first
      end
    end
  end

  # Provides marshalling support for use by the Marshal library.
  # @param _hash [Hash] Hash object
  def marshal_load(_hash)
    clear
    _hash.each do |_key, _value|
      instance_variable_set(_key, _value)
    end
  end
  
  # Provides marshalling support for use by the Marshal library.
  # @return [Hash] Hash object
  def marshal_dump
    _hash                    = {}
    _hash[:@dirname        ] = @dirname
    _hash[:@platform_id    ] = @platform_id
    _hash[:@platform_name  ] = @platform_name
    _hash[:@product_id     ] = @product_id
    _hash[:@product_name   ] = @product_name
    _hash[:@product_version] = @product_version
    _hash[:@product_date   ] = @product_date
    _hash[:@region_id      ] = @region_id
    _hash[:@region_name    ] = @region_name
    _hash[:@country_id     ] = @country_id
    _hash[:@maker_id       ] = @maker_id
    _hash[:@maker_name     ] = @maker_name
    _hash[:@description    ] = @description
    _hash
  end

#------------------------------------------------------------------------------
# Public Member Variables
#------------------------------------------------------------------------------

  attr_reader :dirname
  attr_reader :luid
  attr_reader :platform_id
  attr_reader :platform_name
  attr_reader :product_id
  attr_reader :product_name
  attr_reader :product_version
  attr_reader :product_date
  attr_reader :region_id
  attr_reader :region_name
  attr_reader :country_id
  attr_reader :maker_id
  attr_reader :maker_name
  attr_reader :description

#==============================================================================
#                                   PRIVATE
#==============================================================================

  private

  # Initializes the directory. Returns +true+ if directory is valid, otherwise 
  # +false+.
  # @param _dirname [String] Directory name
  # @return [Boolean] +true+ if directory is valid, otherwise +false+.
  def init_dir(_dirname)
    @dirname = _dirname
    @luid    = Digest::SHA2.hexdigest(@dirname)
    
    _result   = true
    _result &&= has_dir?(@dirname)
    _result &&= has_dir?(@dirname, CFG.root_dir)
    _result
  end

  # Initializes the configuration. Returns +true+ if configuration is valid, 
  # otherwise +false+.
  # @return [Boolean] +true+ if configuration is valid, otherwise +false+.
  def init_config
    _result   = true
    _result &&= check_etc(CFG, :platform_files       )
    _result &&= check_etc(CFG, :platform_endianness  )
    _result &&= check_etc(CFG, :platform_compressions)
    _result &&= check_etc(CFG, :region_ids           )
    _result &&= check_etc(CFG, :country_ids          )
    _result &&= check_etc(CFG, :maker_ids            )
    _result &&= check_etc(CFG, :maker_names          )
    _result &&= check_etc(CFG, :product_ids          )
    _result &&= check_etc(CFG, :product_names        )
    _result
  end

  # Initializes the platform. Returns +true+ if platform has been detected, 
  # otherwise +false+.
  # @return [Boolean] +true+ if platform has been detected, otherwise +false+.
  def init_platform
    _result = false
    PLATFORMS.find do |_id, _name|
      _files  = CFG.platform_files[_id]
      _result = _files.all? do |_path|
        _path   = join(_path)
        _msg    = sprintf(VOC.check_file, _path)
        _result = !Dir.glob(_path).empty?
        
        if _result
          _msg += sprintf(' - %s', VOC.exists)
          ALX::LOG.info(_msg)
        else
          _msg += sprintf(' - %s', VOC.not_found)
          ALX::LOG.warn(_msg)
        end
        
        _result
      end
      
      @platform_id   = _id
      @platform_name = _name
      refresh_etc

      _result
    end

    if _result
      _msg  = sprintf(VOC.check_platform, @platform_id)
      _msg += sprintf(' - %s (%s)', VOC.identified, @platform_name)
      ALX::LOG.info(_msg)
    else
      _msg  = sprintf(VOC.check_platform, PLATFORMS.keys.sort.join(', '))
      _msg += sprintf(' - %s', VOC.not_matched)
      ALX::LOG.error(_msg)
    end

    _result
  end

  # Initializes the BNR file. Returns +true+ if BNR file is valid, otherwise 
  # +false+.
  # @return [Boolean] +true+ if BNR file is valid, otherwise +false+.
  def init_bnr
    _path = join(CFG.bnr_file)
    unless has_file?(_path)
      return false
    end
    
    _bnr = BnrFile.new
    _bnr.load(_path)
    
    @product_name = _bnr.product_name
    @maker_name   = _bnr.maker_name
    @description  = _bnr.description
    _result       = false
    refresh_etc

    _msg = sprintf(VOC.check_bnr, VOC.product_name)
    if @product_name =~ cfg(:product_names)
      _result  = true
      _msg    += sprintf(' - %s (%s)', VOC.valid    , @product_name)
      ALX::LOG.info(_msg)
    else
      _result  = false
      _msg    += sprintf(' - %s (%s)', VOC.incorrect, @product_name)
      ALX::LOG.error(_msg)
    end
    
    if _result
      _msg = sprintf(VOC.check_bnr, VOC.maker_name)
      if @maker_name =~ cfg(:maker_names)
        _result  = true
        _msg    += sprintf(' - %s (%s)', VOC.valid    , @maker_name)
        ALX::LOG.info(_msg)
      else
        _result  = false
        _msg    += sprintf(' - %s (%s)', VOC.incorrect, @maker_name)
        ALX::LOG.error(_msg)
      end
    end
    
    _result
  end

  # Initializes the HDR file. Returns +true+ if HDR file is valid, otherwise 
  # +false+.
  # @return [Boolean] +true+ if HDR file is valid, otherwise +false+.
  def init_hdr
    _path = join(CFG.hdr_file)
    unless has_file?(_path)
      return false
    end
    
    _hdr = HdrFile.new
    _hdr.load(_path)

    @product_id  = _hdr.product_id
    @region_id   = _hdr.region_id
    refresh_etc

    @region_name = cfg(:region_ids)  || ''
    @country_id  = cfg(:country_ids) || ''
    @maker_id    = _hdr.maker_id
    _result      = false
    refresh_etc

    _msg = sprintf(VOC.check_hdr, VOC.product_id)
    if @product_id =~ cfg(:product_ids)
      _result  = true
      _msg    += sprintf(' - %s (%s)', VOC.valid    , @product_id)
      ALX::LOG.info(_msg)
    else
      _result  = false
      _msg    += sprintf(' - %s (%s)', VOC.incorrect, @product_id)
      ALX::LOG.error(_msg)
    end
    
    if _result
      _msg = sprintf(VOC.check_hdr, VOC.region_id)
      unless @region_name.empty?
        _result  = true
        _msg    += sprintf(' - %s (%s)', VOC.valid    , @region_id)
        ALX::LOG.info(_msg)
      else
        _result  = false
        _msg    += sprintf(' - %s (%s)', VOC.incorrect, @region_id)
        ALX::LOG.error(_msg)
      end
    end
    
    if _result
      _msg  = sprintf(VOC.check_hdr, VOC.region_name)
      _msg += sprintf(' - %s (%s)', VOC.valid, @region_name)
      ALX::LOG.info(_msg)
    end

    if _result
      _msg = sprintf(VOC.check_hdr, VOC.country_id)
      if COUNTRIES.include?(@country_id)
        _result  = true
        _msg    += sprintf(' - %s (%s)', VOC.valid    , @country_id)
        ALX::LOG.info(_msg)
      else
        _result  = false
        _msg    += sprintf(' - %s (%s)', VOC.incorrect, @country_id)
        ALX::LOG.error(_msg)
      end
    end

    if _result
      _msg = sprintf(VOC.check_hdr, VOC.maker_id)
      if @maker_id =~ cfg(:maker_ids)
        _result  = true
        _msg    += sprintf(' - %s (%s)', VOC.valid    , @maker_id)
        ALX::LOG.info(_msg)
      else
        _result  = false
        _msg    += sprintf(' - %s (%s)', VOC.incorrect, @maker_id)
        ALX::LOG.error(_msg)
      end
    end

    if _result
      _msg = sprintf(VOC.check_hdr, VOC.product_name)
      if _hdr.product_name =~ cfg(:product_names)
        _result  = true
        _msg    += sprintf(' - %s (%s)', VOC.valid    , _hdr.product_name)
        ALX::LOG.info(_msg)
      else
        _result  = false
        _msg    += sprintf(' - %s (%s)', VOC.incorrect, _hdr.product_name)
        ALX::LOG.error(_msg)
      end
    end
    
    _result
  end

  # Initializes the IP.BIN file. Returns +true+ if IP.BIN file is valid, 
  # otherwise +false+.
  # @return [Boolean] +true+ if IP.BIN file is valid, otherwise +false+.
  def init_ip
    _path = join(CFG.ip_file)
    unless has_file?(_path)
      return false
    end
    
    _ip = IPFile.new
    _ip.load(_path)
    
    @product_id      = _ip.product_id
    @product_name    = _ip.product_name
    @product_version = _ip.product_version
    @product_date    = _ip.product_date
    @region_id       = _ip.region_id
    @maker_id        = _ip.maker_id
    @maker_name      = _ip.maker_name
    @description     = _ip.description
    refresh_etc

    @region_name     = cfg(:region_ids)  || ''
    @country_id      = cfg(:country_ids) || ''
    _result          = false
    refresh_etc

    _msg = sprintf(VOC.check_ip, VOC.product_id)
    if @product_id =~ cfg(:product_ids)
      _result  = true
      _msg    += sprintf(' - %s (%s)', VOC.valid    , @product_id)
      ALX::LOG.info(_msg)
    else
      _result  = false
      _msg    += sprintf(' - %s (%s)', VOC.incorrect, @product_id)
      ALX::LOG.error(_msg)
    end

    if _result
      _msg = sprintf(VOC.check_ip, VOC.product_name)
      if @product_name =~ cfg(:product_names)
        _result  = true
        _msg    += sprintf(' - %s (%s)', VOC.valid    , @product_name)
        ALX::LOG.info(_msg)
      else
        _result  = false
        _msg    += sprintf(' - %s (%s)', VOC.incorrect, @product_name)
        ALX::LOG.error(_msg)
      end
    end

    if _result
      _msg  = sprintf(VOC.check_ip, VOC.product_version)
      _msg += sprintf(' - %s (%s)', VOC.valid, @product_version)
      ALX::LOG.info(_msg)
    end

    if _result
      _msg  = sprintf(VOC.check_ip, VOC.product_date)
      _msg += sprintf(' - %s (%s)', VOC.valid, @product_date)
      ALX::LOG.info(_msg)
    end

    if _result
      _msg = sprintf(VOC.check_ip, VOC.region_id)
      unless @region_name.empty?
        _result  = true
        _msg    += sprintf(' - %s (%s)', VOC.valid    , @region_id)
        ALX::LOG.info(_msg)
      else
        _result  = false
        _msg    += sprintf(' - %s (%s)', VOC.incorrect, @region_id)
        ALX::LOG.error(_msg)
      end
    end

    if _result
      _msg  = sprintf(VOC.check_ip, VOC.region_name)
      _msg += sprintf(' - %s (%s)', VOC.valid, @region_name)
      ALX::LOG.info(_msg)
    end

    if _result
      _msg = sprintf(VOC.check_ip, VOC.maker_id)
      if @maker_id =~ cfg(:maker_ids)
        _result  = true
        _msg    += sprintf(' - %s (%s)', VOC.valid    , @maker_id)
        ALX::LOG.info(_msg)
      else
        _result  = false
        _msg    += sprintf(' - %s (%s)', VOC.incorrect, @maker_id)
        ALX::LOG.error(_msg)
      end
    end

    if _result
      _msg = sprintf(VOC.check_ip, VOC.maker_name)
      if @maker_name =~ cfg(:maker_names)
        _result  = true
        _msg    += sprintf(' - %s (%s)', VOC.valid    , @maker_name)
        ALX::LOG.info(_msg)
      else
        _result  = false
        _msg    += sprintf(' - %s (%s)', VOC.incorrect, @maker_name)
        ALX::LOG.error(_msg)
      end
    end

    if _result
      _msg = sprintf(VOC.check_ip, VOC.country_id)
      if COUNTRIES.include?(@country_id)
        _result  = true
        _msg    += sprintf(' - %s (%s)', VOC.valid    , @country_id)
        ALX::LOG.info(_msg)
      else
        _result  = false
        _msg    += sprintf(' - %s (%s)', VOC.incorrect, @country_id)
        ALX::LOG.error(_msg)
      end
    end

    if _result
      _msg  = sprintf(VOC.check_ip, VOC.description)
      _msg += sprintf(' - %s (%s)', VOC.valid, @description)
      ALX::LOG.info(_msg)
    end
    
    _result
  end

  # Refreshes the ETC attribute resolver.
  def refresh_etc
    @etc_resolver.clear
    @etc_resolver << @platform_id  unless @platform_id.empty?
    
    if !@country_id.empty?
      @etc_resolver << @country_id
    elsif !@region_id.empty?
      @etc_resolver << @region_id
    end
    
    @etc_resolver << @product_id   unless @product_id.empty?
    @etc_resolver << @product_date unless @product_date.empty?
    @etc_resolver << @description  unless @description.empty?
  end

  # Returns +true+ if the ETC attribute is valid, otherwise +false+.
  # 
  # @param _etc [ETC]    ETC object
  # @param _sym [Symbol] ETC attribute symbol
  # 
  # @return [Boolean] +true+ if ETC attribute is valid, otherwise +false+.
  def check_etc(_etc, _sym)
    _attr   = _etc.send(_sym)
    _ids    = PLATFORMS.select do |_platform, _| 
      _attr.find do |_key, _|
        _key.split('-').first == _platform
      end
    end
    _result = !_ids.empty?
    
    _msg = sprintf(VOC.check_etc, "#{_etc.symbol}.#{_sym}")
    if _result
      _msg += sprintf(' - %s (%s)', VOC.valid, _ids.keys.join(', '))
      ALX::LOG.info(_msg)
    else
      _msg += sprintf(' - %s', VOC.incorrect)
      ALX::LOG.error(_msg)
    end
    
    _result
  end
  
end # class Root

# -- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --

end # module ALX

# -- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --

ALX::Main.call do
  ALX::Root.init
end
