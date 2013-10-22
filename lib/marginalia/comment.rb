require 'socket'

module Marginalia
  module Comment
    mattr_accessor :components, :lines_to_ignore

    def self.update!(controller = nil)
      @controller = controller
    end

    def self.construct_comment
      ret = ''
      self.components.each do |c|
        component_value = self.send(c)
        if component_value.present?
          ret << ',' if ret.present?
          ret << c.to_s << ':' << component_value.to_s
        end
      end
      ret
    end

    def self.clear!
      @controller = nil
    end

    private
      def self.application
        if defined? Rails.application
          Marginalia.application_name ||= Rails.application.class.name.split("::").first
        else
          Marginalia.application_name ||= "rails"
        end

        Marginalia.application_name
      end

      def self.controller
        @controller.controller_name if @controller.respond_to? :controller_name
      end

      # Namespaced controller. Admin::UsersController => admin/users
      def self.controller_path
        @controller.controller_path if @controller.respond_to? :controller_path
      end

      def self.action
        @controller.action_name if @controller.respond_to? :action_name
      end

      # ActionDispatch request identifier
      def self.uuid
        @controller.request.try(:uuid) if @controller.respond_to? :request
      end

      # Terse controller path, action, and uuid. E.g.
      #   admin/users#show:a6a3f74880dc66dcc788d6075c8ea8a2
      def self.source
        if @controller
          "#{controller_path}##{action}:#{uuid}"
        else
          'unknown request'
        end
      end

      def self.line
        Marginalia::Comment.lines_to_ignore ||= /\.rvm|gem|vendor|marginalia|rbenv/
        last_line = caller.detect do |line|
          line !~ Marginalia::Comment.lines_to_ignore
        end
        if last_line
          root = if defined?(Rails) && Rails.respond_to?(:root)
            Rails.root.to_s
          elsif defined?(RAILS_ROOT)
            RAILS_ROOT
          else
            ""
          end
          if last_line.starts_with? root
            last_line = last_line[root.length..-1]
          end
          last_line
        end
      end

      def self.hostname
        @cached_hostname ||= Socket.gethostname
      end

      def self.pid
        Process.pid
      end

  end

end
