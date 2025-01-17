module Hyrax
  module Workflow
    module WorkflowFactoryDecorator
      def create_workflow_entity!
        Sipity::Entity.find_or_create_by!(proxy_for_global_id: work.to_global_id.to_s) do |e|
          e.workflow = work.active_workflow
          e.workflow_state = nil
        end
      end
    end
  end
end
Hyrax::Workflow::WorkflowFactory.prepend(Hyrax::Workflow::WorkflowFactoryDecorator)
