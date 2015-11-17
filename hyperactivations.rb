require 'csv'
require 'date'
require 'time'
require 'active_support'
require 'time_difference'
require 'english'
require 'pry'

class Hyperactivations
  def initialize
    @weeks = 3
    @id = []
    setID()
    @hours = []
    setHours()
    @dispensers = []
    setDispensers()
    @output = []
  end

  # Extract all unique dispenser IDs and sort them
  def setID
    @weeks.times do |i|
      mincount = CSV.foreach("#{i+1}_mintime.csv", headers: true) {|row| @id << row[0].to_i }
    end
    @id.sort!.uniq!
  end

  # Extract all unique hours and sort them
  def setHours
    @weeks.times do |i|
      CSV.open("#{i+1}_mincount.csv", 'r') do |csv| 
        csv.first.each do |date|
          if !date.nil? && date != "dispenser_id"
            @hours << date 
          end
        end
      end
    end
    @hours.sort!.uniq!
    # @hours.sort!.uniq!.map! { |date| DateTime.strptime(date, '%m-%d %H')}
  end

  # Create a matrix of dispensers and their corresponding hours
  def setDispensers
    @id.each_with_index do |dispenser, index|
      @dispensers << [dispenser]
      @hours.each do |hours|
        @dispensers[index] << [hours, "", "", "", ""]
      end
    end
  end

  # Find the index in the dispenser matrix using ID of a dispenser
  def findIndex(array, id)
    array.each_with_index do |row, index|
      return index if row[0] == id
    end
  end

  # Extract the header as a key
  def setTimeKey(name)
    key = []
    CSV.open(name, 'r') do |csv|
      csv.first.each do |date|
        key << date
      end
    end
    return key.drop(1)
  end

  # Find the correct index for the specified dispenser. Then, match the correct min values to the corresponding time array.
  def assignCounts(fileName, position, min)
    timeKey = setTimeKey(fileName)
    CSV.foreach(fileName, headers: true) do |row|
      # Extract the ID index in the dispenser matrix and then drop the ID from the main row
      id = row[0].to_i
      row = row.drop(1)
      idIndex = findIndex(@dispensers, id)

      # Set 'dispenserValues' as the matrix row corresponding to that dispenser id
      dispenserValues = @dispensers[idIndex].drop(1)

      # Assign values to dispenser's time arrays corresponding to values in the mincount csv
      row.each_with_index do |value, value_index| 
        dispenserIndex = findIndex(dispenserValues, timeKey[value_index]) + 1
        currentValue = @dispensers[idIndex][dispenserIndex][position]
        if min
          @dispensers[idIndex][dispenserIndex][position] = "" if value[1] == ""
          @dispensers[idIndex][dispenserIndex][position] = value[1].to_i if (currentValue == "" || currentValue > value[1].to_i)
        else
          @dispensers[idIndex][dispenserIndex][position] = "" if value[1] == ""
          @dispensers[idIndex][dispenserIndex][position] = value[1].to_i if (currentValue == "" || currentValue < value[1].to_i)
        end
      end
    end
  end

  def assignTimes(fileName, position, min)
    timeKey = setTimeKey(fileName)
    CSV.foreach(fileName, headers: true) do |row|
      # Extract the ID index in the dispenser matrix and then drop the ID from the main row
      id = row[0].to_i
      row = row.drop(1)
      idIndex = findIndex(@dispensers, id)

      # Set 'dispenserValues' as the matrix row corresponding to that dispenser id
      dispenserValues = @dispensers[idIndex].drop(1)
      
      # Assign values to dispenser's time arrays corresponding to values in the mincount csv
      row.each_with_index do |value, value_index| 
        dispenserIndex = findIndex(dispenserValues, timeKey[value_index]) + 1
        currentValue = @dispensers[idIndex][dispenserIndex][position]
        if min
          @dispensers[idIndex][dispenserIndex][position] = "" if value[1] == ""
          @dispensers[idIndex][dispenserIndex][position] = value[1].to_i if (currentValue == "" || currentValue > value[1].to_i)
        else
          @dispensers[idIndex][dispenserIndex][position] = "" if value[1] == ""
          @dispensers[idIndex][dispenserIndex][position] = value[1].to_i if (currentValue == "" || currentValue < value[1].to_i)
        end
      end

    end
  end

  def output
    @dispensers.each do |dispenser_row|
      output_row = []
      dispenser_row.each do |time|
        output_row << dispenser_row[0]
        time.each do |value|
          output_row << value
        end
      end
      @output << output_row
    end
    CSV.open("output.csv", "w") do |csv|
      @output.each do |row|
        csv << row
      end
    end
  end

  def run
    initialize()
    @weeks.times do |i|
      assignCounts("#{i+1}_mincount.csv", 1, true)
      puts "#{i+1}_mincount.csv done..."
      assignCounts("#{i+1}_maxcount.csv", 2, false)
      puts "#{i+1}_maxcount.csv done..."
      assignCounts("#{i+1}_mintime.csv", 3, true)
      puts "#{i+1}_mintime.csv done..."
      assignCounts("#{i+1}_maxtime.csv", 4, false)
      puts "#{i+1}_maxtime.csv done..."
    end
    output()
  end
end

new = Hyperactivations.new
new.run
