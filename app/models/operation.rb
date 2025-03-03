# frozen_string_literal: true

# Модель Operation
class Operation < Sequel::Model
  # many_to_one :user

  class << self
    attr_reader :oper, :user

    def calculate(params)
      res = validate_calculate(params)
      return res unless res.success?

      @user = User[params[:user_id]]
 
      return Result.error('Клиент не найден!') unless user

      ids = params[:positions].map { _1[:id] }
      prods = Product.find_by(ids).each_with_object({}) { _2[_1[:id]] = _1 }

      res = {
        status: 200,
        user: {
          id: user[:id],
          template_id: user.template[:id],
          name: user[:name],
          bonus: user[:bonus].to_f
        }
      }
      res[:operation_id] = 0
      res[:summ] = 0.0

      summ = cashback_summ = discount_summ = noloyalty_summ = 0.0

      res[:positions] = params[:positions].each_with_object([]) do |pos, poss|
        pos[:type] = prods[pos[:id]] ? prods[pos[:id]][:type] : nil
        pos[:value] = prods[pos[:id]] ? prods[pos[:id]][:value] : nil

        cost = pos[:price].to_f * pos[:quantity]

        case pos[:type]
        when 'discount'
          pos[:type_desc] = "Дополнительная скидка #{pos[:value]}%"
          pos[:discount_percent], pos[:discount_summ] = prod_discount(cost, pos[:value])
        when 'increased_cashback'
          pos[:type_desc] = "Дополнительный кэшбек #{pos[:value]}%"
          pos[:discount_percent], pos[:discount_summ] = prod_discount(cost, 0)
          cashback_summ += cost * pos[:value].to_f / 100
        when 'noloyalty'
          pos[:type_desc] = 'Не участвует в системе лояльности'
          pos[:discount_percent] = 0.0
          pos[:discount_summ] = 0.0
          noloyalty_summ += cost
        else
          pos[:type_desc] = nil
          pos[:discount_percent], pos[:discount_summ] = prod_discount(cost, 0)
        end

        discount_summ += pos[:discount_summ]
        summ += cost
        poss << pos
      end

      res[:discount] = {}
      res[:cashback] = {}

      summ_for_cash = (summ - noloyalty_summ - discount_summ - cashback_summ)
      per_cash = user.template[:cashback].to_f / 100

      res[:cashback][:will_add] =
        templ_type == 2 ? cashback_summ.round : (cashback_summ + summ_for_cash * per_cash).round

      res[:discount][:summ] = discount_summ.round(2)
      res[:discount][:value] = "#{(res[:discount][:summ] / summ * 100).round(2)}%"

      res[:cashback][:value] = "#{(res[:cashback][:will_add] / summ * 100).round(2)}%"
      res[:cashback][:existed_summ] = res[:user][:bonus]
      res[:cashback][:allowed_summ] = (summ - noloyalty_summ - discount_summ).round(2)

      res[:summ] = summ - res[:discount][:summ]

      begin
        add_operation_by(res)

        res[:operation_id] = oper[:id]

        Result.success(res)
      rescue StandardError => e
        Result.error("Ошибка выполенния: #{e.message}")
      end
    end

    def submit(params)
      res = validate_calculate(params)
      return res unless res.success?

      @oper = self[params[:operation_id]]

      return 'Операция отсутсвует!' unless oper
      return 'Операция уже проведена!' if oper[:done]

      @user = User[params[:user][:id]]
      return 'Клиент не найден!' unless user

      return 'Недостаточно баллов для списания!' if params[:write_off] > oper[:allowed_write_off]

      res = {
        status: 200,
        message: 'Данные успешно обработаны!',
        operation: { user_id: user[:id] }
      }

      res[:operation][:discount] = oper[:discount].to_f.to_s
      res[:operation][:discount_percent] = oper[:discount_percent].to_f.to_s

      summ = oper[:allowed_write_off] - params[:write_off]
      per_cash = user.template[:cashback].to_f / 100
      prod_cash = (oper[:cashback] - oper[:allowed_write_off] * per_cash) / (1 - per_cash)
      check_summ = oper[:check_summ] - params[:write_off]

      res[:operation][:cashback] = if templ_type == 2
                                     ((1 - params[:write_off] / check_summ) * oper[:cashback]).round
                                   else
                                     (prod_cash + (summ - prod_cash) * per_cash).round
                                   end

      res[:operation][:cashback_percent] = (res[:operation][:cashback] / check_summ * 100).round
      res[:operation][:write_off] = params[:write_off]
      res[:operation][:check_summ] = check_summ.round

      begin
        update_operation_by(res)

        Result.success(res)
      rescue StandardError => e
        Result.error("Ошибка выполенния: #{e.message}")
      end
    end

    private

    def add_operation_by(params)
      @oper = create(
        user_id: params[:user][:id],
        cashback: params[:cashback][:will_add],
        cashback_percent: params[:cashback][:value].to_f,
        discount: params[:discount][:summ],
        discount_percent: params[:discount][:value].to_f,
        write_off: 0,
        check_summ: params[:summ],
        done: false,
        allowed_write_off: params[:cashback][:allowed_summ]
      )
    end

    def update_operation_by(params)
      oper.update(
        cashback: params[:operation][:cashback],
        cashback_percent: params[:operation][:cashback_percent],
        discount: params[:operation][:discount],
        discount_percent: params[:operation][:discount_percent].to_f,
        write_off: params[:operation][:write_off],
        check_summ: params[:operation][:check_summ],
        done: true
      )
    end

    def prod_discount(cost, val)
      if templ_type.zero?
        [val.to_f, (val.to_f * cost / 100).round(2)]
      else
        per_dis = val.to_f + user.template[:discount].to_f
        [per_dis, (per_dis * cost / 100).round(2)]
      end
    end

    def templ_type 
      @templ_type ||= Template::TYPE[user.template[:name]]
    end

    def validate_calculate(params)
      # здесь возможно дописать валидацию по параметрам пока оставил заглушку
      Result.success(params)
    end

    def validate_submit(params)
      # здесь возможно дописать валидацию по параметрам пока оставил заглушку
      Result.success(params)
    end
  end
end

# CREATE TABLE IF NOT EXISTS "operations"
# (
# 	id INTEGER not null
# 		constraint operation_pk
# 			primary key autoincrement,
# 	user_id INT not null
# 		references "users",
# 	cashback numeric not null,
# 	cashback_percent numeric not null,
# 	discount numeric not null,
# 	discount_percent numeric not null,
# 	write_off numeric,
# 	check_summ numeric not null,
# 	done boolean
# , allowed_write_off numeric);
# CREATE UNIQUE INDEX operation_id_uindex
# 	on "operations" (id);
