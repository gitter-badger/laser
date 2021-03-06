RSpec.describe GitLoader do
  it "instantiates a loader" do
    expect(GitLoader.new).not_to be nil
  end

  describe "#get_git_from_api" do
    it "returns nil if api response is an error", :ci => true do
      repo_name = "xspond/paranoid"
      loader = GitLoader.new
      expect(loader.get_git_from_api(repo_name)).to be nil
    end
  end

  describe "#fetch_assignees" do
      before :example do
        @loader = GitLoader.new
      end
      it "saves an instance of ownership for each assignee in the array", :ci => true do
        tz = LaserGem.create(name: "tzinfo")
        loader2 = GemLoader.new
        loader2.fetch_and_create_gem_spec(tz)
        @loader.fetch_assignees(tz)
        expect(Ownership.count).not_to be 0
        expect(Ownership.count).not_to be nil
      end

      it "updates an existing ownership if the handles match", :ci => true do

        tz = LaserGem.create(name: "tzinfo")
        loader2 = GemLoader.new
        loader2.fetch_and_create_gem_spec(tz)
        expect(Ownership.where(["github_owner = ?", true]).count).to be 0
        @loader.fetch_assignees(tz)

        expect(Ownership.where(["github_owner = ? and rubygem_owner = ?", true, true]).count).not_to be 0
      end

      it "correctly populates ownerships for each laser_gem" , :ci => true do
        tz = LaserGem.create(name: "tzinfo")
        loader2 = GemLoader.new
        loader2.fetch_and_create_gem_spec(tz)
        repo_name = @loader.parse_git_uri(tz)
        array = @loader.get_owners_from_github(repo_name)
        @loader.fetch_assignees(tz)
        array.each { |a| expect(Ownership.where(["git_handle = ?", a[0]])[0].git_handle).to eq array[0][0] }
      end

      it "saves instances of ownership for the dependents with the given laser_gem", :ci => true do
        tz = LaserGem.create(name: "tzinfo")
        loader2 = GemLoader.new
        loader2.fetch_and_create_gem_spec(tz)
        ts = LaserGem.find_by(name: "thread_safe")
        @loader.fetch_assignees(tz)
        expect(ts.ownerships.count).not_to be 0
      end

      it "does not save a ownership if it already exists", :ci => true do
        tz = LaserGem.create(name: "tzinfo")
        loader2 = GemLoader.new
        loader2.fetch_and_create_gem_spec(tz)
        ts = LaserGem.find_by(name: "thread_safe")
        @loader.fetch_assignees(tz)
        num = ts.ownerships.count
        @loader.fetch_assignees(ts)
        expect(ts.ownerships.count).to eq num

      end
  end

  describe "#parse_git_uri" do
    def make_spec attributes = {}
      @loader = GitLoader.new
      @laser_gem = create :laser_gem
      @spec = @laser_gem.gem_spec
      @spec.update!(attributes)
    end

    it "does not parse if gem_spec not present" do
      make_spec
      expect(@loader.parse_git_uri(@laser_gem)).to be nil
    end

    it "does not parse if source_code_uri is nil" do
      make_spec source_code_uri: "nil"
      expect(@loader.parse_git_uri(@laser_gem)).to be nil
    end

    it "does not parse if source_code_uri does not include 'github'" do
      make_spec source_code_uri: "www.rails.org"
      expect(@loader.parse_git_uri(@laser_gem)).to be nil
    end

    it "does not parse if source_code_uri is incorrect format" do
      make_spec source_code_uri: "www.github.com/mail/mail/"
      expect(@loader.parse_git_uri(@laser_gem)).to be nil
    end

    it "returns repo name if source_code_uri is in correct format" do
      make_spec source_code_uri: "https://github.com/ruby-gem/rails"
      expect(@loader.parse_git_uri(@laser_gem)).to eq "ruby-gem/rails"
    end
  end

  describe "#fetch_and_create_gem_git", :ci => true  do
    it "saves an instance of GemGit for each laser_gem" do
      loader = GitLoader.new
      loader2 = GemLoader.new
      laser_gem = LaserGem.create!(name: "tzinfo")
      loader2.fetch_and_create_gem_spec(laser_gem)
      loader.fetch_and_create_gem_git(laser_gem)
      expect(GemGit.exists?(name: "tzinfo/tzinfo")).to be true
    end
  end

      it "fetches owners of the LaserGem and creates ownerships", :ci => true do
        tz = LaserGem.create(name: "tzinfo")
        loader = GemLoader.new
        loader.fetch_and_create_gem_spec(tz)
        loader2 = GitLoader.new
        loader2.fetch_assignees(tz)
        expect(Ownership.count).not_to be 0
        expect(Ownership.count).not_to be nil
      end

  describe "#fetch_and_create_gem_git", :ci => true do
    it "calls fetch_and_create_gem_git recursively for the dependents of the given laser_gem, creating their GemGits and ownerships", :ci => true  do
      loader = GemLoader.new
      laser_gem = LaserGem.create(name: "tzinfo")
      loader.fetch_and_create_gem_spec(laser_gem)
      loader2 = GitLoader.new
      loader2.fetch_and_create_gem_git(laser_gem)
      expect(GemGit.exists?(name: "tzinfo/tzinfo")).to be true
      expect(GemGit.exists?(name: "ruby-concurrency/thread_safe")).to be true
      expect(laser_gem.dependencies.map(&:name)).to eq ["thread_safe"]
      ts = LaserGem.find_by(name: "thread_safe")
      expect(ts.ownerships.count).not_to be 0
    end
  end
end
