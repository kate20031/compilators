/**
 ** \file misc/symbol.hxx
 ** \brief Inline implementation of misc::symbol.
 */

#pragma once

#include <misc/symbol.hh>

namespace misc
{
  inline symbol& symbol::operator=(const symbol& rhs)
  {
    super_type::operator=(rhs);
    return *this;
  }

  inline bool symbol::operator==(const symbol& rhs) const
  {
    return this->get() == rhs.get();
  }

  inline bool symbol::operator!=(const symbol& rhs) const
  {
    return !(*this == rhs);
  }

  inline std::ostream& operator<<(std::ostream& ostr, const symbol& the)
  {
    return ostr << the.get();
  }

} // namespace misc
