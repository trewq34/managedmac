require 'pry'
require 'cfpropertylist'
module Puppet::Parser::Functions
  newfunction(:process_mcx_options, :type => :rvalue, :doc => <<-EOS
Returns MCX PropertyList as String.
    EOS
  ) do |args|

    if args.size != 4
      e = "process_mcx_options(): Wrong number of args: #{args.size} for 4"
      raise(Puppet::ParseError, e)
    end

    bluetooth, wifi, loginitems, suppress_icloud_setup = *args

    plist_options = {
      :plist_format => CFPropertyList::List::FORMAT_XML,
      :formatted    => true,
    }

    settings = {
      'com.apple.MCXBluetooth'   => {},
      'com.apple.MCXAirPort'     => {},
      'loginwindow'              => {},
      'com.apple.SetupAssistant' => {},
    }

    case bluetooth
    when TrueClass, FalseClass
      settings['com.apple.MCXBluetooth'] = {
        'DisableBluetooth' => Hash['state', 'always', 'value', bluetooth]
      }
    else
      settings.delete('com.apple.MCXBluetooth')
    end

    case wifi
    when TrueClass, FalseClass
      settings['com.apple.MCXAirPort'] = {
        'DisableAirPort' => Hash['state', 'always', 'value', wifi]
      }
    else
      settings.delete('com.apple.MCXAirPort')
    end

    if loginitems.empty?
      settings.delete('loginwindow')
    else
      values = loginitems.collect do |path|
        Hash['Hide', true, 'Path', path]
      end
      settings['loginwindow'] = {
        'AutoLaunchedApplicationDictionary-raw' => {
          'state' => 'always',
          'upk'   => {
            'mcx_input_key_names'   => ['AutoLaunchedApplicationDictionary-raw'],
            'mcx_output_key_name'   => 'AutoLaunchedApplicationDictionary-managed',
            'mcx_remove_duplicates' => true,
          },
          'value' => values,
        },
        'DisableLoginItemsSuppression' => {
          'state' => 'always',
          'value' => false,
        },
        'LoginUserMayAddItems' => {
          'state' => 'always',
          'value' => true,
        }
      }
    end

    if suppress_icloud_setup
      settings['com.apple.SetupAssistant'] = {
        'DidSeeCloudSetup' => {
          'state' => 'once',
          'value' => true,
        },
        'LastSeenCloudProductVersion' => {
          'state' => 'once',
          'value' => lookupvar('macosx_productversion_major'),
        },
      }
    else
      settings.delete('com.apple.SetupAssistant')
    end

    # binding.pry

    return nil if settings.empty?
    settings.to_plist(plist_options)
  end
end