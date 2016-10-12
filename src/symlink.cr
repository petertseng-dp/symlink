class Symlinks
  @links = {} of String => String

  def ln_s(source : String, target : String)
    source += '/' unless source.ends_with?('/')
    target += '/' unless target.ends_with?('/')
    @links[readlink(source)] = target
  end

  def readlink(link : String) : String
    links_used = Set(String).new
    while (entry = @links.find { |k, v| link.starts_with?(k) })
      k, v = entry
      raise "cycle detected" if links_used.includes?(k)
      link = link.sub(k, v)
      links_used.add(k)
    end
    link
  end
end

class Filesystem
  class Directory
    @children = {} of String => (Directory | String)

    def []?(name : String) : (Directory | String)?
      @children[name]?
    end

    def mkdir(name : String) : Directory
      @children[name] = Directory.new
    end

    def ln_s(name : String, target : String)
      @children[name] = target
    end
  end

  def self.split_path(path : String) : Array(String)
    path.split('/').reject(&.empty?)
  end

  @root = Directory.new

  def ln_s(source : String, target : String)
    path = self.class.split_path(source)
    # We don't do this in an actual filesystem,
    # but this is the assumption in the test.
    dir = mkdir_p(path[0...-1])
    dir.ln_s(path[-1], target)
  end

  def readlink(link : String) : String
    _, target = readlink_internal(link, Set(String).new)
    target
  end

  private def readlink_internal(link : String, links_used : Set(String)) : Tuple(Directory?, String)
    path = self.class.split_path(link)
    path.reduce({@root, ""}) { |(at, cwd), component|
      if at
        case (c = at[component]?)
        when Directory
          {c, "#{cwd}/#{component}"}
        when String
          raise "cycle detected" if links_used.includes?(c)
          readlink_internal(c, links_used.dup.add(c))
        else
          # We're like readlink -m, I guess.
          # We don't care if any intermediate directory doesn't exist.
          # If it doesn't, we'll just blindly append any remaining components.
          {nil, "#{cwd}/#{component}"}
        end
      else
        {nil, "#{cwd}/#{component}"}
      end
    }
  end

  private def mkdir_p(path : Array(String)) : Directory
    path.reduce(@root) { |at, component|
      case (c = at[component]?)
      when Directory
        c
      when String
        mkdir_p(self.class.split_path(c))
      else
        at.mkdir(component)
      end
    }
  end
end
