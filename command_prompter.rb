module Blackjack
  class CommandPrompter
    attr_reader :legend
    attr_reader :valid_inputs
    attr_reader :minimum_integer
    attr_reader :maximum_integer
    attr_reader :input
    attr_reader :output

    attr_accessor :default_value

    def initialize(*valid_cmd_names)
      #
      # usage:
      #   p = CommandPrompter.new("Bet Amount:int:1:10", "Hit", "Stand", "sPlit", "Double")
      #   p.default(25)
      #   p.get_command do |cmd|
      #     case cmd
      #        when "h"
      #           ....
      #        when "p"
      #        else
      #          cmd.to_i
      #     end
      #   end
      #
      #   User sees:
      #
      #     Bet Amount (1 - 10), [H]it, [S]tand, s[P]lit, [D]ouble
      #     ==25==>  
      #
      @input = $stdin
      @output = $stdout
      @default_value = nil

      parse_params_and_configure(valid_cmd_names)
    end

    def get_command
      #
      # yields and/or returns the integer or downcased command letter
      # validated by configured command definitions
      #
      cmd = nil
      while(true) do
        print_legend
        print_prompt
        cmd, lc_cmd = get_input
        next if cmd.empty?
        break if valid_cmd?(lc_cmd)
        print_invalid_cmd(cmd)
      end
      quit_check(lc_cmd)
      yield lc_cmd if block_given?
      lc_cmd
    end

    private

    def print(str)
      output.print str
    end

    def println(str)
      output.puts str 
    end

    def parse_params_and_configure(valid_cmd_names)
      @valid_inputs = ['q']
      @minimum_integer = nil
      @maximum_integer = nil

      commands = []
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
    end

    def get_input
      typed = input.gets.chomp
      if typed.empty? && !default_value.nil?
        typed = default_value.to_s
      end
      [typed, typed.downcase]
    end

    def print_legend
      println legend
    end

    def print_prompt
      print prompt_str
    end

    def prompt_str
      @_prstr ||= ("=>%s" % (default_value.nil? ? "" : "[#{default_value}] "))
    end

    def print_invalid_cmd(cmd)
      println "'#{cmd}' is invalid"
    end

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
