#******************************************************************************
# ALX - Skies of Arcadia Legends Examiner
# Copyright (C) 2024 Marcel Renner
# 
# This file is part of ALX.
# 
# ALX is free software: you can redistribute it and/or modify it under the 
# terms of the GNU General Public License as published by the Free Software 
# Foundation, either version 3 of the License, or (at your CHARAion) any later 
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

require_relative('accessory.rb')
require_relative('stdentrydata.rb')

# -- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --

module ALX

#==============================================================================
#                                    CLASS
#==============================================================================

# Class to handle accessories from binary and/or CSV files.
class AccessoryData < StdEntryData

#==============================================================================
#                                   PUBLIC
#==============================================================================

  public

  # Constructs an AccessoryData.
  # @param _depend [Boolean] Resolve dependencies
  def initialize(_depend = true)
    super(Accessory, _depend)
    self.id_range  = dscrptr(:accessory_id_range)
    self.data_file = dscrptr(:accessory_data_files)
    self.name_file = dscrptr(:accessory_name_files)
    self.dscr_file = dscrptr(:accessory_dscr_files)
    self.csv_file  = join(CFG.accessory_csv_file)
    self.tpl_file  = File.join(CFG.build_dir, CFG.accessory_tpl_file)
  end

end # class AccessoryData

# -- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --

end # module ALX
