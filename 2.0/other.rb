require 'csv'
require 'date'
require 'time'
require 'active_support'
require 'time_difference'
require 'english'
require 'pry'
require 'progressbar'
class Hyperactivations
  def initialize
    init = ProgressBar.new("Initializing", 5)
    @weeks = 3
    @time_cutoff = 1
    @created_at = []

    @id = []
    setID()
    init.inc

    @hours = []
    setHours()
    init.inc

    @dispensers = []
    setDispensers()
    init.inc

    @processed_output = []
    @hourKey = []
    init.inc

    @hourly_output = []
    setAverages()
    init.inc

    @average_output = []

    init.finish

    @output = []
  end

  # Extract all unique dispenser IDs and sort them
  def setID
    @weeks.times do |i|
      CSV.foreach("#{i+1}_mintime.csv", headers: true) {|row| @id << row[0].to_i }
      CSV.foreach("#{i+1}_events.csv", headers: true) {|row| @id << row[0].to_i }
      CSV.foreach("#{i+1}_mincount.csv", headers: true) {|row| @id << row[0].to_i }
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
      CSV.open("#{i+1}_events.csv", 'r') do |csv| 
        csv.first.each do |date|
          if !date.nil? && date != "dispenser_id"
            @hours << date 
          end
        end
      end
      CSV.open("#{i+1}_mintime.csv", 'r') do |csv| 
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
        @dispensers[index] << [hours, 0, 0, 0, 0, 0]
      end
    end
  end

  def setAverages
    @hourKey = [["00", 0, 0, 0, 0, 0, 0, 0], ["01", 0, 0, 0, 0, 0, 0, 0], ["02", 0, 0, 0, 0, 0, 0, 0], ["03", 0, 0, 0, 0, 0, 0, 0], ["04", 0, 0, 0, 0, 0, 0, 0], ["05", 0, 0, 0, 0, 0, 0, 0], ["06", 0, 0, 0, 0, 0, 0, 0], ["07", 0, 0, 0, 0, 0, 0, 0], ["08", 0, 0, 0, 0, 0, 0, 0], ["09", 0, 0, 0, 0, 0, 0, 0], ["10", 0, 0, 0, 0, 0, 0, 0], ["11", 0, 0, 0, 0, 0, 0, 0], ["12", 0, 0, 0, 0, 0, 0, 0], ["13", 0, 0, 0, 0, 0, 0, 0], ["14", 0, 0, 0, 0, 0, 0, 0], ["15", 0, 0, 0, 0, 0, 0, 0], ["16", 0, 0, 0, 0, 0, 0, 0], ["17", 0, 0, 0, 0, 0, 0, 0], ["18", 0, 0, 0, 0, 0, 0, 0], ["19", 0, 0, 0, 0, 0, 0, 0], ["20", 0, 0, 0, 0, 0, 0, 0], ["21", 0, 0, 0, 0, 0, 0, 0], ["22", 0, 0, 0, 0, 0, 0, 0], ["23", 0, 0, 0, 0, 0, 0, 0]] 
    @dispensers.each do |row| 
      list = Array.new(24)
      list = list.each_with_index.map do |hour, index|
        if index >= 10
          hour = ["#{index}", 0, 0, 0, 0, 0, 0, 0] 
        else
          hour = ["0#{index}", 0, 0, 0, 0, 0, 0, 0] 
        end
      end
      @hourly_output << ([row[0]] + list) 
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
  def assignCounts(fileName, position)
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
        @dispensers[idIndex][dispenserIndex][position] = value[1].to_i 
      end
    end
  end

  def assignEvents(fileName, position)
    timeKey = setTimeKey(fileName)
    CSV.foreach(fileName, headers: true) do |row|
      # Extract the ID index in the dispenser matrix and then drop the ID from the main row
      id = row[0].to_i
      next if id < 1000
      row = row.drop(1)
      idIndex = findIndex(@dispensers, id)

      # Set 'dispenserValues' as the matrix row corresponding to that dispenser id
      dispenserValues = @dispensers[idIndex].drop(1)

      # Assign values to dispenser's time arrays corresponding to values in the mincount csv
      row.each_with_index do |value, value_index| 
        dispenserIndex = findIndex(dispenserValues, timeKey[value_index]) + 1
        currentValue = @dispensers[idIndex][dispenserIndex][position]

        @dispensers[idIndex][dispenserIndex][position] += value[1].to_i 
      end
    end
  end

  def calculateProcessed
    @dispensers.each do |row|
      id = row[0]
      new_row = row.drop(1)
      output_row = [id]

      new_row.each do |hour|
        processed_row = [hour[0]]
        if hour[1] == "empty" 
          processed_row = processed_row + ["empty", "empty", "empty"]
        else
          activations = hour[2] - hour[1]
          activations += 1 if hour[2] > 0
          time = hour[4] - hour[3]
          time += 1 if hour[4] > 0
          events = hour[5]
          processed_row = processed_row + [activations, time, events]
        end
        output_row << processed_row
      end
      @processed_output << output_row
    end
  end

  def checkEmpty
    CSV.foreach("created_at.csv", headers: true) do |row| 
      @created_at << row 
    end
    @processed_output.each do |row|
      current_id = row[0]
      created_date = nil

      # Find the created_at date @of currently processed dispenser
      @created_at.each do |created_row|
        if created_row[0].to_i == current_id.to_i
          created_date = DateTime.parse(created_row[1])
        end
      end

      # Replace empty with 0s if the time is after created_at time
      row[1..-1].each do |time_row|
        current_time = DateTime.strptime(time_row[0], "%m-%d %H")
        if created_date.nil?
          next
        elsif created_date < current_time && time_row[1] == "empty"
          time_row[1] = 0
          time_row[2] = 0
          time_row[3] = 0
        end
      end
    end
  end

  def calculateHourly
    @processed_output.each do |row|
      id = row[0]
      idIndex = findIndex(@hourly_output, id)
      row.drop(1).each do |hour|
        bucket = hour[0][6..8]
        bucketIndex = findIndex(@hourKey, bucket) + 1
        # Times skipped = 4
        if hour[1] == 0
          @hourly_output[idIndex][bucketIndex][4] += 1
        # Times where interval wasn't good enough = 5
        elsif hour[2] < @time_cutoff
          @hourly_output[idIndex][bucketIndex][5] += 1
        # Times where no activations = 6
        # elsif hour[1] == 0 
        #   @hourly_output[idIndex][bucketIndex][6] += 1
        #   @hourly_output[idIndex][bucketIndex][6] += 1
        else
          # Activations = 1, time_interval = 2, events = 3 | new 1 = summed activations, 2 = summed events, 3 = summed ratio, 4 = missing, 5 = hourly cutoff counts, 6 = total counts, 7 = total time
          @hourly_output[idIndex][bucketIndex][1] += hour[1]
          @hourly_output[idIndex][bucketIndex][2] += hour[3]
          @hourly_output[idIndex][bucketIndex][3] += hour[1].to_f/hour[3].to_f if hour[1] > 0
          @hourly_output[idIndex][bucketIndex][6] += 1
          @hourly_output[idIndex][bucketIndex][7] += hour[2]
        end
      end
    end
  end

  def calculateAverages
    @hourly_output.each do |row|
      new_output = Array.new
      new_output = [row[0]]
      row[1..-1].each do |time_row|
        new_row = [time_row[0]]
        if time_row[6] == 0
          new_row += [0, 0, 0, 0, 0, time_row[4] + time_row[5], 0, 0]
        else
          n = time_row[6].to_f
          time = time_row[7].to_f
          # Average activations
          new_row << time_row[1].to_f/n
          new_row << time_row[1].to_f/time
          # Average events
          new_row << time_row[2].to_f/n
          new_row << time_row[2].to_f/time
          # Average ratio
          new_row << time_row[3].to_f/n
          # total time
          new_row << time_row[7]
          # n used
          new_row << time_row[6]
          # n unused
          new_row << time_row[4] + time_row[5]
        end
        new_output << new_row
      end
      @average_output << new_output
    end
  end

  def output
    pbar = ProgressBar.new("Finalizing", @hourly_output.length)
    @average_output.each do |hourly_row|
      output_row = []
      output_row << hourly_row[0]
      hourly_row.drop(1).each do |time|
        time.drop(1).each do |value|
          output_row << value
        end
      end
      @output << output_row
      pbar.inc
    end
    pbar.finish

    pbar = ProgressBar.new("Writing", @output.length)
    CSV.open("output.csv", "w") do |csv|
      @output.each do |row|
        csv << row
        pbar.inc
      end
    end
    pbar.finish
  end

  def dropDispensers(array)
    array.delete_if {|row| row[0] < 10000}
  end

  def run
    initialize()

    pbar = ProgressBar.new("Processing", @weeks*5)

    @weeks.times do |i|
      assignCounts("#{i+1}_mincount.csv", 1)
      pbar.inc
      assignCounts("#{i+1}_maxcount.csv", 2)
      pbar.inc
      assignCounts("#{i+1}_mintime.csv", 3)
      pbar.inc
      assignCounts("#{i+1}_maxtime.csv", 4)
      pbar.inc
      assignEvents("#{i+1}_events.csv", 5)
      pbar.inc
    end
    pbar.finish
    pbar = ProgressBar.new("Calculating", 4)
    dropDispensers(@dispensers)
    dropDispensers(@hourly_output)
    pbar.inc 

    calculateProcessed()
    pbar.inc

    @dispensers=[]
    checkEmpty()
    calculateHourly()
    pbar.inc

    calculateAverages()
    pbar.inc
    pbar.finish
    output()
  end
end

new = Hyperactivations.new
new.run
