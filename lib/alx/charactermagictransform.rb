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

require_relative('charactermagicdata.rb')
require_relative('stdentrytransform.rb')

# -- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --

module ALX

#==============================================================================
#                                    CLASS
#==============================================================================

# Base class to export and/or import character magics to and/or from CSV files.
class CharacterMagicTransform < StdEntryTransform

#==============================================================================
#                                   PUBLIC
#==============================================================================

  public

  # Constructs a CharacterMagicTransform.
  def initialize
    super(CharacterMagicData)
  end

end # class CharacterMagicTransform

# -- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --

end # module ALX
