module Blackjack
  class Prompt
    attr_reader :legend
    attr_reader :valid_inputs
    attr_reader :minimum_integer
    attr_reader :maximum_integer
    attr_reader :input
    attr_reader :output

    def initialize(*valid_cmd_names)
      #
      # usage:
      #   p = Prompt.new("Bet Amount:int:1:10", "Hit", "Stand", "sPlit", "Double")
      #   p.prompt do |cmd|
      #     case cmd
      #        when "h"
      #           ....
      #        when "p"
      #        else
      #          cmd.to_i
      #     end
      #   end
      #
      commands = []
      @valid_inputs = ['q']
      @minimum_integer = nil
      @maximum_integer = nil
      valid_cmd_names.each do |cmd|
        scmd = cmd.split(':')
        nc = scmd.length
        if nc > 1
          case scmd[1]
            when 'int'
              @minimum_integer = scmd[2].to_i
              if nc == 4
                @maximum_integer = scmd[3].to_i
                guide = " (#{minimum_integer} - #{maximum_integer})"
              else
                guide = " ( >= #{minimum_integer})"
              end
              commands << scmd[0] + guide 
            else
              raise "invalid command type"
          end
        else
          cap_let = cmd.match(/[A-Z]/)[0]
          valid_inputs << cap_let.downcase
          commands << cmd.gsub(/([A-Z])/, "[\\1]")
        end
      end
      @legend = commands.join(", ") + " or [Q]uit"
      @input = $stdin
      @output = $stdout
    end

    def prompt
      invalid = true
      cmd = nil
      while(true) do
        println legend
        print "=> "
        cmd = getline
        next if cmd.empty?
        dcmd = cmd.downcase
        break if valid_cmd?(dcmd)
        println "'#{cmd}' is invalid"
      end
      quit_check(dcmd)
      yield dcmd if block_given?
      dcmd
    end

    def getline
      input.gets.chomp
    end

    def print(str)
      output.print str
    end

    def println(str)
      output.puts str 
    end

    private

    def quit_check(dcmd)
      exit if dcmd == 'q'
    end

    def valid_cmd?(dcmd)
      valid_inputs.include?(dcmd) || (
        is_integer? && dcmd =~ /^\d+$/ &&
        dcmd.to_i >= minimum_integer && (maximum_integer.nil? || dcmd.to_i <= maximum_integer)
      )
    end

    def is_integer?
      !minimum_integer.nil?
    end
  end
end
