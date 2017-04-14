require "./core_ext/*"
require "./crDFA/**"

module DFA
  module V1
    class Expression
      def to_graph
        self.class.to_graph(@graph, @expression)
      end

      def self.to_graph(graph, expression = "")
        node_ids = Hash(Node, Int32).new
        id = 0
        id_for_node = ->(node : Node) { node_ids[node] ||= (id += 1); node_ids[node] }
        node = ->(node : Node) { %{Graph::Easy::Node->new( name => '#{id_for_node.call(node)}', label => '#{node.name}' )} }
        edges = graph.map_with_index do |g, index|
          g.next.map do |s|
            <<-perl
            my \\$a = #{node.call(g)};
            \\$a->set_attribute('rows', 2);
            #{if g.name == "Start"
                "\\$a->set_attribute('flow', 'up');"
              end}
            my \\$b = #{node.call(s)};
            #{if g.name == "End"
                "\\$a->set_attribute('flow', 'up');"
              end}
            \\$b->set_attribute('rows', 2);
            \\$graph->add_edge(\\$a, \\$b);
          perl
          end.join("\n")
        end
        program = %{
          use Graph::Easy;
          my \\$graph = Graph::Easy->new();
          \\$graph->set_attribute('flow', 'up');
          #{edges.join("\n")}
          print \\$graph->as_boxart();
        }.delete("\n").gsub(/\s+/, " ").strip
        "/#{expression}/\n" + `perl -Mutf8 -CS -e "#{program}"`
      end
    end
  end
end

def char_cmp(mc : Char)
  ->(c : Char) { c == mc }
end
