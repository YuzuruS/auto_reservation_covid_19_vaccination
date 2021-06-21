namespace :reserve do
  desc "1回目 東京"
  task :first => :environment do
    city_code = ENV['CITY_CODE']
    visit_number = ENV['VISIT_NUMBER']
    birth_year = ENV['BIRTH_YEAR']
    birth_month = ENV['BIRTH_MONTH']
    birth_day = ENV['BIRTH_DAY']


    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--no-sandbox')
    client = Selenium::WebDriver::Remote::Http::Default.new
    client.read_timeout = 60 # seconds

    d = Selenium::WebDriver.for :chrome, options: options, http_client: client
    w = Selenium::WebDriver::Wait.new(timeout: 60)
    d.get 'https://www.vaccine.mrso.jp/sdftokyo/VisitNumbers/visitnoAuth'

    w.until {
      d.find_element(:name, 'data[VisitnoAuth][name]').displayed? &&
      d.find_element(:name, 'data[VisitnoAuth][visitno]').displayed?
    }

    d.find_element(:name, 'data[VisitnoAuth][name]').send_keys(city_code)
    d.find_element(:name, 'data[VisitnoAuth][visitno]').send_keys(visit_number)
    
    el = d.find_element(:name, 'data[VisitnoAuth][year]')
    select = Selenium::WebDriver::Support::Select.new(el)
    select.select_by(:text, birth_year)

    el = d.find_element(:name, 'data[VisitnoAuth][month]')
    select = Selenium::WebDriver::Support::Select.new(el)
    select.select_by(:text, birth_month)

    el = d.find_element(:name, 'data[VisitnoAuth][day]')
    select = Selenium::WebDriver::Support::Select.new(el)
    select.select_by(:text, birth_day)

    d.find_element(:xpath, "//button[contains(text(), '次へ進む')]").click

    w.until {
      d.find_element(:xpath, "//button[contains(text(), '予約を進める')]").displayed?
    }

    d.find_element(:xpath, "//button[contains(text(), '予約を進める')]").click

    w.until {
      d.find_element(:xpath, "//h3[contains(text(), '接種会場⼀覧')]").displayed?
    }


    place_start_id = 44665
    place_end_id = 44668

    day_start_id = 806
    #day_end_id = 
    judgement_text = '選択された日付の予約は既に埋まっております。'
    loop do
      (place_start_id..place_end_id).each do |place|
        base_url = "https://www.vaccine.mrso.jp/sdftokyo/CustomReserves/input/#{place}/894"
        p base_url
        begin
          d.get base_url
        rescue
          sleep(3)
          d.switch_to.alert.accept
        end
        sleep(2)
        if d.find_element(:xpath, '//*[@id="input"]/div[3]//div[1]').text.include?("選択された日付の予約は既に埋まっております。")
          next
        end

        d.find_element(:xpath, '//*[@id="inputForm"]/div[2]/div/table').text
        line_notify = LineNotify.new(ENV['LINE_NOTIFY_TOKEN'])
        reservation_count = d.find_elements(:xpath, '//*[@id="inputForm"]/div[3]/div/div/div[2]/div[1]/div[1]/div').count
        target_el = rand(reservation_count)
        div_el_num = target_el.zero?  ? 'div' : "div[#{target_el.to_s}]"
        reservation_time = d.find_element(:xpath, '//*[@id="inputForm"]/div[3]/div/div/div[2]/div[1]/div[1]/' + div_el_num + '/a')
        options = {message: "予約可能やで!!!\nURL: #{base_url}\n#{d.find_element(:xpath, '//*[@id="inputForm"]/div[2]/div/table').text}\n#{reservation_time.text}"}
        line_notify.ping(options)
        

        reservation_time.click

        w.until {
          d.find_element(:xpath, "//button[contains(text(), '予約内容確認')]").displayed?
        }
        d.find_element(:xpath, "//button[contains(text(), '予約内容確認')]").click
    
        w.until {
          d.find_element(:xpath, "//button[contains(text(), '予約する')]").displayed?
        }
        d.find_element(:xpath, "//button[contains(text(), '予約する')]").click
  

        if d.find_elements(:xpath, '//*[@id="detail"]/div/div/div/div[1]').count.zero?
          options = {message: "予約成功!!"}
          line_notify.ping(options)
          break
        else
          options = {message: "予約失敗"}
          line_notify.ping(options)
        end
      end
    end

  end
end