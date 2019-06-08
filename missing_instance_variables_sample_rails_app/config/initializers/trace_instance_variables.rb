def tracer(target_class_name, target_instance_variable_name)
  TracePoint.trace(:line) do |tp|
    # ソース取得
    begin
      line = File.open(tp.path, "r"){|f| f.readlines[tp.lineno - 1] }
    rescue Errno::ENOENT => e
    end
    next unless line
    # AST取得
    begin
      node = RubyVM::AbstractSyntaxTree.parse(line).children.last
    rescue Exception => e # 乱暴
      next
    end
    # インスタンス変数への代入かを調べる
    next unless node.type == :IASGN
    # クラス名を調べる
    target_class = Kernel.const_get(target_class_name)
    next unless tp.self.is_a?(target_class)
    # インスタンス変数名を調べる
    instance_variable_name = node.children.first
    next unless instance_variable_name == target_instance_variable_name.to_sym
    puts "#{target_class_name} #{target_instance_variable_name} is assigned in #{tp.path}:#{tp.lineno} #{tp.method_id} #{tp.defined_class}"
  end
end

tracer("BooksController", "@books")

# Started GET "/books" for ::1 at 2019-06-08 12:13:53 +0900
# Processing by BooksController#index as HTML
# BooksController @books is assigned in /box/github_repos/github.com/igaiga/tmrk01/missing_instance_variables_sample_rails_app/app/controllers/books_controller.rb:7 index BooksController
#   Rendering books/index.html.erb within layouts/application
#   Book Load (6.5ms)  SELECT "books".* FROM "books"
#   ↳ app/views/books/index.html.erb:15
#   Rendered books/index.html.erb within layouts/application (232.4ms)
# Completed 200 OK in 2852ms (Views: 2720.4ms | ActiveRecord: 6.5ms)

