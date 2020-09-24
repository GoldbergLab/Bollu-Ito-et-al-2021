classdef ControlEventData < event.EventData
   properties
      Control
   end
   
   methods
      function data = ControlEventData(control)
         data.Control = control;
      end
   end
end