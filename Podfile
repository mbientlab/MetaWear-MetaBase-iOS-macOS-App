# Uncomment this line to define a global platform for your project
platform :ios, '14.5'
use_frameworks!

def all_pods
  pod 'MetaWear', :subspecs => ['UI', 'AsyncUtils', 'Mocks', 'DFU']
  pod 'PNChart'
  pod 'MBProgressHUD'
  pod 'RMessage', '~> 2.3.4'
  pod 'DeviceKit'
end

target 'MetaBase' do
  all_pods
  target 'MetaBaseTests' do
    inherit! :search_paths
    #pod 'Firebase'
  end
end

target 'MetaWear' do
  all_pods
  inherit! :search_paths
end

