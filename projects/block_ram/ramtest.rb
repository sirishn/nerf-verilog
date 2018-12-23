#!/usr/bin/ruby

require 'OpalKelly'


class DESTester
  def InitializeDevice
    @xem = OpalKelly::FrontPanel.new
    if (OpalKelly::FrontPanel::NoError != @xem.OpenBySerial(""))
      puts "A device could not be opened.  Is one connected?"
      return(false)
    end

    if (OpalKelly::FrontPanel::BrdXEM3001v2 == @xem.GetBoardModel)
      puts "Device model: XEM3001v2"
    end

    if (OpalKelly::FrontPanel::BrdXEM3010 == @xem.GetBoardModel)
      puts "Device model: XEM3010"
    end
    
    @xem.LoadDefaultPLLConfiguration

    # Get some general information about the device.
    puts "Device firmware version: #{@xem.GetDeviceMajorVersion}.#{@xem.GetDeviceMinorVersion}"
    puts "Device serial number: #{@xem.GetSerialNumber}"
    puts "Device ID: #{@xem.GetDeviceID}"

    # Download the configuration file.
    if (OpalKelly::FrontPanel::NoError != @xem.ConfigureFPGA("block_ram_test.bit"))
      puts "FPGA configuration failed."
      return(false)
    end

    # Check for FrontPanel support in the FPGA configuration.
    if (false == @xem.IsFrontPanelEnabled)
      puts "FrontPanel support is not available."
      return(false)
    end
    
    print "FrontPanel support is available."
    return(true)
  end


  def SetKey(key)
    8.times do |i|
      @xem.SetWireInValue((0x0f-i), key[i], 0xff)
    end
    @xem.UpdateWireIns
  end


  def ResetDES
    @xem.SetWireInValue(0x10, 0xff, 0x01)
    @xem.UpdateWireIns
    @xem.SetWireInValue(0x10, 0x00, 0x01)
    @xem.UpdateWireIns
  end


  def EncryptDecrypt(infile, outfile)
    fileIn = File.new(infile, "rb")
    fileOut = File.new(outfile, "wb")

    # Reset the RAM address pointer.
    @xem.ActivateTriggerIn(0x41, 0)

    while (buf = fileIn.read(2048))
      got = buf.size
      if (got == 0)
        break
      end

      if (got < 2048)
        buf += "\x00"*(2048-got)
      end

      # Write a block of data.
      @xem.ActivateTriggerIn(0x41, 0)
      @xem.WriteToPipeIn(0x80, buf)

      # Perform DES on the block.
      @xem.ActivateTriggerIn(0x40, 0)

      # Wait for the TriggerOut indicating DONE.
      10.times do
        @xem.UpdateTriggerOuts()
        if (@xem.IsTriggered(0x60, 1))
          break
        end
      end

      @xem.ReadFromPipeOut(0xa0, buf)
      fileOut.write(buf)
    end
    
    fileIn.close
    fileOut.close
  end

  def WriteRAM
    write_array = []
    for i in (1..512) do
      write_array+=[i]
    end
    buf = write_array.pack("f*")
    write_array.each { |i| print i.to_s + " " }
    puts ""
    @xem.WriteToPipeIn(0x80, buf)
  end

  def ReadRAM
    buf = ""
    for i in (1..512) do
      buf+= "\x00\x00\x00\x00"	#32-bit data
    end
  
    @xem.ReadFromPipeOut(0xa0, buf)
    read_array = buf.unpack("f*")
    read_array.each { |i| print i.to_s+" " }
    puts ""
  end

  def Compute
    # Perform DES on the block.
    @xem.ActivateTriggerIn(0x40, 0)
    puts "sending execute"
    # Wait for the TriggerOut indicating DONE.
    10.times do
      @xem.UpdateTriggerOuts()
      if (@xem.IsTriggered(0x60, 1))
        break
        puts "execute complete"
      end
    end
  end

  def Encrypt(infile, outfile)
    puts "Encrypting #{infile} ----> #{outfile}"
    # Set the encrypt Wire In.
    @xem.SetWireInValue(0x0010, 0x0000, 0x0010)
    @xem.UpdateWireIns
    EncryptDecrypt(infile, outfile)
  end


  def Decrypt(infile, outfile)
    puts "Decrypting #{infile} ---> #{outfile}"
    # Set the decrypt Wire In.
    @xem.SetWireInValue(0x0010, 0x00ff, 0x0010)
    @xem.UpdateWireIns
    EncryptDecrypt(infile, outfile)
  end
end


# Main code
puts "------ DES Encrypt/Decrypt Tester in Python ------"
des = DESTester.new
if (false == des.InitializeDevice)
  exit
end

des.ResetDES

puts "Writing..."
des.WriteRAM

puts "Computing..."
des.Compute


puts "Reading..."
des.ReadRAM

#if (ARGV.size != 4)
#  puts "Usage: DESTester [d|e] key infile outfile"
#  puts "   [d|e]   - d to decrypt the input file.  e to encrypt it."
#  puts "   key     - 64-bit hexadecimal string used for the key."
#  puts "   infile  - an input file to encrypt/decrypt."
#  puts "   outfile - destination output file."
#  exit
#end

# Get the hex digits entered as the key
#key = []
#strkey = ARGV[1]
#8.times do |i|
#  key << strkey[(i*2)..(i*2+1)].to_i(16)
#end
#des.SetKey(key)

# Encrypt or decrypt
#if (ARGV[0] == 'd')
#  des.Decrypt(ARGV[2], ARGV[3])
#else
#  des.Encrypt(ARGV[2], ARGV[3])
#end

