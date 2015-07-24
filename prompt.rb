module Blackjack
  class Prompt
    attr_reader :legend
    attr_reader :valid_inputs
    attr_reader :input
    attr_reader :output

    def initialize(*valid_cmd_names)
      #
      # usage:
      #   p = Prompt.new("Hit", "Stand", "sPlit", "Double")
      #   p.prompt do |cmd|
      #     case cmd
      #        when "Hit"
      #           ....
      #        when "sPlit"
      #     end
      #   end
      #
      commands = []
      @valid_inputs = []
      valid_cmd_names.each do |cmd|
        cap_let = cmd.match(/[A-Z]/)[0]
        valid_inputs << cap_let.downcase
        commands << cmd.gsub(/([A-Z])/, "[\\1]")
      end
      @legend = commands[0..-2].join(", ") + " or " + commands[-1]
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
        break if valid_inputs.include?(cmd.downcase)
      end
      yield cmd if block_given?
      cmd
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
  end
end
