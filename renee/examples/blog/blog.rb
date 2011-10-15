class Blog
  attr_reader :posts

  def initialize
    @posts = []
    @post_id = 0
  end

  def new_post(title, contents)
    @posts << Post.new(self, @post_id += 1, title, contents)
  end

  def find_post(id)
    @posts.find{|p| p.id == id}
  end

  def delete_post(post)
    @posts.delete(post)
  end

  class Post
    attr_reader :id, :created_at, :updated_at
    attr_accessor :title, :contents

    def initialize(blog, id, title, contents)
      @blog, @id, @title, @contents, @created_at = blog, id, title, contents, Time.new
      @updated_at = @created_at
    end

    def touch!
      @updated_at = Time.new
    end

    def title=(title)
      touch!
      @title = title
    end

    def contents=(contents)
      touch!
      @contents = contents
    end

    def delete!
      @blog.delete_post(self)
    end
  end
end