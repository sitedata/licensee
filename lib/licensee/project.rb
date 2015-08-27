class Licensee
  class Project
    attr_reader :repository, :revision

    # Initializes a new project
    #
    # path_or_repo path to git repo or Rugged::Repository instance
    # revsion - revision ref, if any
    def initialize(path_or_repo, revision = nil)
      if path_or_repo.kind_of? Rugged::Repository
        @repository = path_or_repo
      else
        begin
          @repository = Rugged::Repository.new(path_or_repo)
        rescue Rugged::RepositoryError
          raise if revision
          @repository = FilesystemRepository.new(path_or_repo)
        end
      end

      @revision = revision
    end

    # Returns the matching Licensee::License instance if a license can be detected
    def license
      @license ||= matched_file.match if matched_file
    end

    def license_file
      @license_file ||= files.select { |f| f.license? }.sort_by { |f| f.license_score }.last
    end

    def package_file
      return unless Licensee.package_manager_files?
      @package_file ||= files.select { |f| f.package? }.sort_by { |f| f.package_score }.last
    end

    def matched_file
      license_file || package_file
    end

    private

    def commit
      @commit ||= revision ? repository.lookup(revision) : repository.last_commit
    end

    def tree
      @tree ||= commit.tree.select { |blob| blob[:type] == :blob }
    end

    def files
      @files ||= tree.map { |blob| ProjectFile.new(repository.lookup(blob[:oid]), blob[:name]) }
    end
  end
end
